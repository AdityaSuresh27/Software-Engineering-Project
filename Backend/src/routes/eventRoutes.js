const express = require("express");
const router = express.Router();
const eventController = require("../controllers/eventcontroller");

// Create an event
router.post("/", eventController.createEvent);

// Get all events for a user
router.get("/user/:userId", eventController.getEventsByUser);

// Update an event
router.put("/:id", eventController.updateEvent);

// Delete an event
router.delete("/:id", eventController.deleteEvent);

module.exports = router;
