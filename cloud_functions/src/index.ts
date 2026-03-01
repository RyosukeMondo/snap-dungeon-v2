import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

admin.initializeApp();
const db = admin.firestore();

/**
 * Generates a deterministic daily seed and stores it in Firestore.
 * Runs at UTC 00:00 daily via Cloud Scheduler.
 */
export const generateDailySeed = functions.scheduler
  .onSchedule("every day 00:00", async () => {
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    const seedStr = today.replace(/-/g, "");
    const hash = crypto.createHash("sha256").update(seedStr).digest();
    const seed = hash.readInt32BE(0); // First 4 bytes as signed int

    await db.doc(`daily_seeds/${today}`).set({
      seed: seed,
      date: today,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`Generated daily seed for ${today}: ${seed}`);
  });

/**
 * Resets daily leaderboard at UTC 00:00.
 * Archives yesterday's scores and distributes rewards to top players.
 */
export const resetLeaderboard = functions.scheduler
  .onSchedule("every day 00:00", async () => {
    const yesterday = new Date(Date.now() - 86400000)
      .toISOString()
      .split("T")[0];

    // Archive yesterday's top scores
    const topScores = await db
      .collection("scores")
      .where("date", "==", yesterday)
      .orderBy("score", "desc")
      .limit(100)
      .get();

    if (!topScores.empty) {
      const batch = db.batch();
      const archiveRef = db.doc(`leaderboard_archives/${yesterday}`);
      batch.set(archiveRef, {
        date: yesterday,
        entries: topScores.docs.map((doc, i) => ({
          rank: i + 1,
          ...doc.data(),
        })),
        archived_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Distribute Dungeon Shards to top 3
      const rewards = [50, 30, 10]; // Shards for 1st, 2nd, 3rd
      for (let i = 0; i < Math.min(3, topScores.size); i++) {
        const uid = topScores.docs[i].data().uid;
        if (uid) {
          const profileRef = db.doc(`player_profiles/${uid}`);
          batch.update(profileRef, {
            gems: admin.firestore.FieldValue.increment(rewards[i]),
          });
        }
      }

      await batch.commit();
    }

    functions.logger.info(`Archived leaderboard for ${yesterday}`);
  });

/**
 * Verifies a submitted score by checking the play log hash.
 * HTTP trigger called by the game client.
 */
export const verifyScore = functions.https.onCall(async (request) => {
  const { score, seed, hash, actionCount, playerClass } = request.data;

  if (!score || !seed || !hash) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields: score, seed, hash"
    );
  }

  // Reconstruct expected hash
  const content = `${seed}:${playerClass || "warrior"}:${score}:0:`;
  const expectedPrefix = crypto
    .createHash("sha256")
    .update(content)
    .digest("hex")
    .substring(0, 8);

  // Loose verification: check hash prefix matches
  // Full replay verification would require running the game simulation server-side
  const hashPrefix = (hash as string).substring(0, 8);

  return {
    verified: hashPrefix === expectedPrefix,
    score,
    seed,
    actionCount,
  };
});

/**
 * Archives weekly leaderboard every Monday at UTC 00:00.
 * Distributes weekly rewards to top players.
 */
export const weeklyReset = functions.scheduler
  .onSchedule("every monday 00:00", async () => {
    const now = new Date();
    const weekStart = new Date(now.getTime() - 7 * 86400000)
      .toISOString()
      .split("T")[0];
    const weekEnd = now.toISOString().split("T")[0];

    // Get top weekly scores (aggregate across days)
    const weekScores = await db
      .collection("scores")
      .where("date", ">=", weekStart)
      .where("date", "<", weekEnd)
      .orderBy("date")
      .orderBy("score", "desc")
      .limit(500)
      .get();

    // Aggregate best score per player
    const bestScores = new Map<string, { uid: string; score: number }>();
    weekScores.docs.forEach((doc) => {
      const data = doc.data();
      const existing = bestScores.get(data.uid);
      if (!existing || data.score > existing.score) {
        bestScores.set(data.uid, { uid: data.uid, score: data.score });
      }
    });

    // Sort by score descending
    const ranked = Array.from(bestScores.values()).sort(
      (a, b) => b.score - a.score
    );

    // Archive
    const archiveRef = db.doc(`weekly_archives/${weekStart}_${weekEnd}`);
    await archiveRef.set({
      week_start: weekStart,
      week_end: weekEnd,
      entries: ranked.slice(0, 100).map((e, i) => ({ rank: i + 1, ...e })),
      archived_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Weekly rewards for top 10
    const weeklyRewards = [200, 150, 100, 75, 50, 40, 30, 25, 20, 15];
    const batch = db.batch();
    for (let i = 0; i < Math.min(10, ranked.length); i++) {
      const profileRef = db.doc(`player_profiles/${ranked[i].uid}`);
      batch.update(profileRef, {
        gems: admin.firestore.FieldValue.increment(weeklyRewards[i]),
      });
    }
    await batch.commit();

    functions.logger.info(
      `Archived weekly leaderboard: ${weekStart} to ${weekEnd}`
    );
  });
