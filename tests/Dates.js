var assert = require('chai').assert;

suite('Dates', function() {

  test('millisFromStartOfWeek', function(done, server) {
    server.eval(function() {
      var date = moment('2000-01-05T00:00:00+10:00');
      // TODO(aramk) This removes the current timezone info, so it's wrong to use it like this. Revert this test case.
      var date2 = date.toDate().toString();
      var actual = Dates.millisFromStartOfWeek(date);
      var actual2 = Dates.millisFromStartOfWeek(date2);
      // 3 days since Sunday (up to but not including Wednesday).
      var expected = moment.duration(3, 'days').as('milliseconds');
      emit('result', {
        actual: actual,
        actual2: actual2,
        date: date.format(),
        date2: moment(date2).format(),
        expected: expected
      });
    }).once('result', function(result) {
      assert.equal(result.date, result.date2);
      assert.equal(result.actual, result.actual2);
      assert.equal(result.actual, result.expected);
      done();
    });
  });

  test('inBetweenWeek', function(done, server) {
    server.eval(function() {
      // Monday 2 PM - 6 PM
      var startDate = moment('2000-01-03T14:00:00+10:00');
      var endDate = startDate.clone().add(4, 'hours');
      var results = _.map([
        '2000-01-10T13:00:00+10:00',
        '2000-01-17T14:00:00+10:00',
        '2000-01-24T15:00:00+10:00',
        '2000-01-31T18:00:00+10:00',
        '2000-01-03T19:00:00+10:00'
      ], function(date) {
        return Dates.inBetweenWeek(date, startDate, endDate);
      });
      emit('result', results);
    }).once('result', function(result) {
      assert.deepEqual(result, [false, true, true, true, false]);
      done();
    });
  });

  test('inBetweenWeek across days', function(done, server) {
    server.eval(function() {
      // Monday 2 PM - 6 PM
      var startDate = moment('2000-01-01T23:00:00+10:00');
      var endDate = startDate.clone().add(4, 'hours');
      var results = _.map([
        '2000-01-01T22:00:00+10:00',
        '2000-01-01T23:00:00+10:00',
        '2000-01-02T00:00:00+10:00',
        '2000-01-02T03:00:00+10:00',
        '2000-01-02T04:00:00+10:00'
      ], function(date) {
        return Dates.inBetweenWeek(date, startDate, endDate);
      });
      emit('result', {
        startDateMillis: Dates.millisFromStartOfWeek(startDate),
        endDateMillis: Dates.millisFromStartOfWeek(endDate),
        results: results
      });
    }).once('result', function(result) {
      assert.isTrue(result.startDateMillis > result.endDateMillis);
      assert.deepEqual(result.results, [false, true, true, true, false]);
      done();
    });
  });

  test('inBetweenWeek on monday', function(done, server) {
    server.eval(function() {
      // Monday 2 PM - 6 PM
      var startDate = moment('2000-01-03T13:00:00+11:00');
      var endDate = startDate.clone().add(3, 'hours');
      var results = _.map([
        '2000-01-17T12:00:00+11:00',
        '2000-01-17T13:00:00+11:00',
        '2000-01-17T14:00:00+11:00',
        '2000-01-17T16:00:00+11:00',
        '2000-01-17T17:00:00+11:00'
      ], function(date) {
        return Dates.inBetweenWeek(date, startDate, endDate);
      });
      emit('results', results);
    }).once('results', function(results) {
      assert.deepEqual(results, [false, true, true, true, false]);
      done();
    });
  });

  test('inBetweenWeek on wednesday', function(done, server) {
    server.eval(function() {
      // Wed 1PM - 5PM
      var startDate = moment('Wed Aug 27 2014 13:03:43 GMT+1000 (EST)');
      var endDate = moment('Wed Aug 27 2014 17:03:43 GMT+1000 (EST)');
      var results = _.map([
        // Wed 5 AM
        'Wed Mar 08 2000 05:04:00 GMT+1100 (EST)'
      ], function(date) {
        return Dates.inBetweenWeek(date, startDate, endDate);
      });
      emit('results', results);
    }).once('results', function(results) {
      assert.deepEqual(results, [false]);
      done();
    });
  });

  test('daysUntilWeekday', function(done, server) {
    server.eval(function() {
      // Saturday
      var startDate = moment('2000-01-01T23:00:00+10:00');
      var results = [];
      for (var i = 0; i <= Dates.MAX_DAY_INDEX; i++) {
        results.push(Dates.daysUntilWeekday(startDate, i));
      }
      emit('results', results);
    }).once('results', function(results) {
      assert.deepEqual(results, [1, 2, 3, 4, 5, 6, 0]);
      done();
    });
  });

  test('getNextWeekday', function(done, server) {
    server.eval(function() {
      // Saturday
      var startDate = moment('2000-01-01T23:00:00+10:00');
      var results = [];
      for (var i = 0; i <= Dates.MAX_DAY_INDEX; i++) {
        results.push(Dates.getNextWeekday(startDate, i));
      }
      emit('results', results);
    }).once('results', function(results) {
      assert.deepEqual(results, [
        '2000-01-02T23:00:00+10:00',
        '2000-01-03T23:00:00+10:00',
        '2000-01-04T23:00:00+10:00',
        '2000-01-05T23:00:00+10:00',
        '2000-01-06T23:00:00+10:00',
        '2000-01-07T23:00:00+10:00',
        '2000-01-01T23:00:00+10:00'
      ]);
      done();
    });
  });

});
