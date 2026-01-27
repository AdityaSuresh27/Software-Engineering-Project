const Task = require("../models/Task");

/**
 * Create a new task
 */
exports.createTask = async (req, res) => {
  try {
    const { title, estimatedTime, deadline, userId } = req.body;

    if (!userId || !title || !estimatedTime) {
      return res.status(400).json({ message: "userId, title, and estimatedTime are required" });
    }

    const task = await Task.create({
      title,
      estimatedTime,
      deadline,
      userId
    });

    res.status(201).json(task);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * Get all tasks for a specific user
 */
exports.getTasksByUser = async (req, res) => {
  try {
    const userId = req.params.userId;
    const tasks = await Task.find({ userId }).sort({ deadline: 1 });
    res.json(tasks);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * Update task (status, actualTime, title, etc.)
 */
exports.updateTask = async (req, res) => {
  try {
    const taskId = req.params.id;
    const updates = req.body;

    const task = await Task.findByIdAndUpdate(taskId, updates, { new: true });

    if (!task) {
      return res.status(404).json({ message: "Task not found" });
    }

    res.json(task);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * Delete a task
 */
exports.deleteTask = async (req, res) => {
  try {
    const taskId = req.params.id;
    const task = await Task.findByIdAndDelete(taskId);

    if (!task) {
      return res.status(404).json({ message: "Task not found" });
    }

    res.json({ message: "Task deleted successfully" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};
