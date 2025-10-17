import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { pool } from './src/db.js';
import healthRouter from './src/routes/health.js';
import authRouter from './src/routes/auth.js';
import genericRouter from './src/routes/generic.js';
import matchesExtraRouter from './src/routes/matches_extra.js';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

app.get('/', (req, res) => res.json({ name: 'PlayMatch Backend', version: '1.0.0' }));

app.use('/api/health', healthRouter);
app.use('/api/auth', authRouter);

// Generic CRUD (protected)
app.use('/api', genericRouter);

// Extra endpoints
app.use('/api/matches', matchesExtraRouter);

// 404
app.use((req, res) => res.status(404).json({ message: 'Not found' }));

// Start
const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
