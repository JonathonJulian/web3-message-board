/**
 * Custom processors for Artillery load tests
 */

// Generate a random string of specified length
function randomString(length) {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return result;
}

// Pick a random item from an array
function randomPickOne(array) {
  return array[Math.floor(Math.random() * array.length)];
}

// Generate a random item object
function generateRandomItem(userContext, events, done) {
  userContext.vars.randomItem = {
    name: `Generated Item ${randomString(8)}`,
    description: `This is a randomly generated item for load testing - ${new Date().toISOString()}`,
    priority: randomPickOne(['low', 'medium', 'high']),
    tags: Array.from({ length: Math.floor(Math.random() * 5) + 1 }, () => randomString(6))
  };

  return done();
}

// Log an event after each request for debugging
function logResponse(requestParams, response, context, ee, next) {
  console.log(`[${new Date().toISOString()}] Request to ${requestParams.url} returned ${response.statusCode}`);
  return next();
}

// Export the functions
module.exports = {
  randomString,
  randomPickOne,
  generateRandomItem,
  logResponse
};