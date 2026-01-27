require('dotenv').config();

const connectDB = require('./config/db');
const app = require('./app');

console.log('Starting DB connection...');
connectDB();

const PORT = 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
