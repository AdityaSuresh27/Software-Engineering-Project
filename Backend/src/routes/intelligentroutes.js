const express = require("express");
const router = express.Router();
const intelligenceController = require("../controllers/intelligentcontroller");

// Get daily workload summary
router.get("/daily/:userId", intelligenceController.getDailyWorkload);
// Check overcommitment
router.get("/overcommitment/:userId", intelligenceController.checkOvercommitment);

router.get("/procrastination/:userId", intelligenceController.analyzeProcrastination);

router.get("/burnout/:userId", intelligenceController.analyzeBurnout);

router.get("/studyplan/:userId", intelligenceController.suggestStudySessions);

module.exports = router;
