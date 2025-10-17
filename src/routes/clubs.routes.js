const router = require('express').Router();
const { listClubs, createClub } = require('../controllers/clubs.controller');
const { protect } = require('../middleware/auth');

router.get('/', protect, listClubs);
router.post('/', protect, createClub);

module.exports = router;
