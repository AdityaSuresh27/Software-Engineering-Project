const Task = require("../models/Task");
const Event = require("../models/Event");

/**
 * Get user's daily workload summary
 */
const getDailyWorkload = async (req, res) => {
  try {
    const userId = req.params.userId;
    const date = req.query.date ? new Date(req.query.date) : new Date();

    const startOfDay = new Date(date.setHours(0,0,0,0));
    const endOfDay = new Date(date.setHours(23,59,59,999));

    const tasks = await Task.find({
      userId,
      deadline: { $gte: startOfDay, $lte: endOfDay }
    });

    const events = await Event.find({
      userId,
      startTime: { $lte: endOfDay },
      endTime: { $gte: startOfDay }
    });

    const totalTaskTime = tasks.reduce((sum, t) => sum + t.estimatedTime, 0);
    const totalEventTime = events.reduce((sum, e) => {
      const start = e.startTime < startOfDay ? startOfDay : e.startTime;
      const end = e.endTime > endOfDay ? endOfDay : e.endTime;
      return sum + (end - start)/60000; // convert ms to minutes
    }, 0);

    res.json({
      date: startOfDay,
      taskCount: tasks.length,
      eventCount: events.length,
      totalTaskTime,
      totalEventTime,
      totalWorkloadMinutes: totalTaskTime + totalEventTime
    });

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * Check overcommitment for a user on a given day
 */
const checkOvercommitment = async (req, res) => {
  try {
    const userId = req.params.userId;
    const date = req.query.date ? new Date(req.query.date) : new Date();

    const startOfDay = new Date(date.setHours(0,0,0,0));
    const endOfDay = new Date(date.setHours(23,59,59,999));

    const tasks = await Task.find({
      userId,
      deadline: { $gte: startOfDay, $lte: endOfDay }
    });

    const events = await Event.find({
      userId,
      startTime: { $lte: endOfDay },
      endTime: { $gte: startOfDay }
    });

    const totalTaskTime = tasks.reduce((sum, t) => sum + t.estimatedTime, 0);
    const totalEventTime = events.reduce((sum, e) => {
      const start = e.startTime < startOfDay ? startOfDay : e.startTime;
      const end = e.endTime > endOfDay ? endOfDay : e.endTime;
      return sum + (end - start)/60000; // minutes
    }, 0);

    const totalWorkload = totalTaskTime + totalEventTime;
    const THRESHOLD = 480; // 8 hours

    res.json({
      date: startOfDay,
      taskCount: tasks.length,
      eventCount: events.length,
      totalTaskTime,
      totalEventTime,
      totalWorkload,
      overcommitment: totalWorkload > THRESHOLD,
      warning: totalWorkload > THRESHOLD ? "⚠️ Overcommitment! Too much workload today." : "OK"
    });

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * Analyze procrastination patterns for a user
 */
const analyzeProcrastination = async (req, res) => {
  try {
    const userId = req.params.userId;

    const tasks = await Task.find({ userId });

    if (tasks.length === 0) {
      return res.json({ message: "No tasks found for this user." });
    }

    const totalTasks = tasks.length;
    const missedTasks = tasks.filter(t => t.status === "missed");
    const completedTasks = tasks.filter(t => t.status === "completed");

    // Last-minute completion = completed close to deadline
    let lastMinuteTasks = 0;
    completedTasks.forEach(t => {
      if (t.deadline && t.actualTime) {
        const timeUntilDeadline = (t.deadline - t.createdAt)/60000; // minutes
        if (t.actualTime >= 0.9 * timeUntilDeadline) {
          lastMinuteTasks++;
        }
      }
    });

    const procrastinationScore = ((missedTasks.length + lastMinuteTasks) / totalTasks * 100).toFixed(1);

    res.json({
      totalTasks,
      missedTasks: missedTasks.length,
      lastMinuteTasks,
      procrastinationScore: `${procrastinationScore}%`,
      warning: procrastinationScore > 50 ? "⚠️ High procrastination risk!" : "OK"
    });

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * Analyze burnout risk over past N days for a user
 */
const analyzeBurnout = async (req, res) => {
  try {
    const userId = req.params.userId;
    const days = req.query.days ? parseInt(req.query.days) : 7; // default 7 days
    const THRESHOLD = 480; // 8 hours/day in minutes

    const today = new Date();
    today.setHours(0,0,0,0);

    let totalWorkloadSum = 0;
    let overloadDays = 0;
    const dailyWorkloads = [];

    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);

      const startOfDay = new Date(date);
      startOfDay.setHours(0,0,0,0);
      const endOfDay = new Date(date);
      endOfDay.setHours(23,59,59,999);

      const tasks = await Task.find({
        userId,
        deadline: { $gte: startOfDay, $lte: endOfDay }
      });

      const events = await Event.find({
        userId,
        startTime: { $lte: endOfDay },
        endTime: { $gte: startOfDay }
      });

      const totalTaskTime = tasks.reduce((sum, t) => sum + t.estimatedTime, 0);
      const totalEventTime = events.reduce((sum, e) => {
        const start = e.startTime < startOfDay ? startOfDay : e.startTime;
        const end = e.endTime > endOfDay ? endOfDay : e.endTime;
        return sum + (end - start)/60000;
      }, 0);

      const totalWorkload = totalTaskTime + totalEventTime;
      totalWorkloadSum += totalWorkload;
      if (totalWorkload > THRESHOLD) overloadDays++;

      dailyWorkloads.push({
        date: startOfDay.toISOString().split('T')[0],
        totalWorkload
      });
    }

    const averageDailyWorkload = (totalWorkloadSum / days).toFixed(1);
    const burnoutRisk = overloadDays >= Math.ceil(days/2); // more than half days overloaded

    res.json({
      userId,
      daysAnalyzed: days,
      dailyWorkloads,
      averageDailyWorkload,
      overloadDays,
      burnoutRisk,
      warning: burnoutRisk ? "⚠️ High burnout risk! Too much workload over last " + days + " days." : "OK"
    });

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * Suggest optimal study sessions for a user on a given day
 */
const suggestStudySessions = async (req, res) => {
  try {
    const userId = req.params.userId;
    const date = req.query.date ? new Date(req.query.date) : new Date();

    const startOfDay = new Date(date.setHours(6,0,0,0)); // start day at 6 AM
    const endOfDay = new Date(date.setHours(22,0,0,0));  // end day at 10 PM

    // Fetch all tasks due today or earlier but not completed
    const tasks = await Task.find({
      userId,
      status: "pending"
    }).sort({ deadline: 1 }); // sort by nearest deadline

    // Fetch all events today
    const events = await Event.find({
      userId,
      startTime: { $lte: endOfDay },
      endTime: { $gte: startOfDay }
    });

    // Build a free time timeline
    let freeSlots = [{ start: startOfDay, end: endOfDay }];
    events.forEach(e => {
      freeSlots = freeSlots.flatMap(slot => {
        // slot fully before or after event -> keep
        if (slot.end <= e.startTime || slot.start >= e.endTime) return [slot];
        // overlap -> split
        const slots = [];
        if (slot.start < e.startTime) slots.push({ start: slot.start, end: e.startTime });
        if (slot.end > e.endTime) slots.push({ start: e.endTime, end: slot.end });
        return slots;
      });
    });

    const suggestedSessions = [];

    // Allocate tasks to free slots
    for (const task of tasks) {
      let taskTimeRemaining = task.estimatedTime; // minutes
      for (let i=0; i<freeSlots.length && taskTimeRemaining > 0; i++) {
        const slot = freeSlots[i];
        const slotMinutes = (slot.end - slot.start)/60000;
        if (slotMinutes <= 0) continue;

        const timeAllocated = Math.min(slotMinutes, taskTimeRemaining);

        suggestedSessions.push({
          task: task.title,
          startTime: new Date(slot.start),
          endTime: new Date(slot.start.getTime() + timeAllocated*60000)
        });

        // Update free slot start
        slot.start = new Date(slot.start.getTime() + timeAllocated*60000);

        // Reduce remaining task time
        taskTimeRemaining -= timeAllocated;
      }

      if (taskTimeRemaining > 0) {
        suggestedSessions.push({
          task: task.title,
          startTime: null,
          endTime: null,
          note: "⚠️ Not enough free time to schedule this task today"
        });
      }
    }

    // Format startTime/endTime nicely
    const formatTime = (d) => d ? d.toTimeString().slice(0,5) : null;

    const formattedSessions = suggestedSessions.map(s => ({
      task: s.task,
      startTime: formatTime(s.startTime),
      endTime: formatTime(s.endTime),
      note: s.note || null
    }));

    res.json({
      userId,
      date: startOfDay.toISOString().split("T")[0],
      suggestedSessions: formattedSessions,
      warning: formattedSessions.some(s => s.note) ? "⚠️ Some tasks could not be fully scheduled!" : "OK"
    });

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// Export all intelligence functions
module.exports = {
  getDailyWorkload,
  checkOvercommitment,
  analyzeProcrastination,
  analyzeBurnout,
  suggestStudySessions
};
