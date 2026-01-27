const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// health check
app.get('/', (req, res) => {
  res.send('Academic Planner Backend Running');
});

// 🔹 ADD THIS
const taskRoutes = require('./routes/taskRoutes');
app.use('/api/tasks', taskRoutes);

const userRoutes = require('./routes/userRoutes');
app.use('/api/users', userRoutes);

const eventRoutes = require("./routes/eventRoutes");
app.use("/api/events", eventRoutes);

const intelligentRoutes = require("./routes/intelligentroutes");
app.use("/api/intelligence", intelligentRoutes);


module.exports = app;
