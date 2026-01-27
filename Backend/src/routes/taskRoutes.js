const express = require("express");
const router = express.Router();
const taskController = require("../controllers/taskcontroller");

// Create a task (requires userId in body)
router.post("/", taskController.createTask);

// Get all tasks for a user
router.get("/user/:userId", taskController.getTasksByUser);

// Update a task
router.put("/:id", taskController.updateTask);

// Delete a task
router.delete("/:id", taskController.deleteTask);

module.exports = router;
