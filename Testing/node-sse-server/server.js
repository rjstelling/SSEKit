#! /usr/bin/env node

var SSE = require('sse')
  , http = require('http');

var myClient;
var nextTimeout;
var reRunCount = 3;
var count = 0;

var test_timeouts = [ 10000, 500, 1200, 2 ];

var tests_cases = [
	"test1",
	" test2",
	"test3 ",
	" test4 ",
];

var server = http.createServer(function(req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('okay');
});

server.listen(8080, '127.0.0.1', function() {
  var sse = new SSE(server);
  sse.on('connection', function(client) {
    //client.send('hi there!');
    myClient = client;
    test(myClient);
  });  
});



function test(client)
{
	var test_case_data = tests_cases[count++];
	myClient.send(test_case_data);
	console.log("["+reRunCount+"] Sending test case "+count+": "+test_case_data+"...");
	
	if(count < tests_cases.length)
	{
		nextTimeout = setTimeout(test, test_timeouts[reRunCount]);
	}
	else
	{
		reRunCount--;
	
		if(reRunCount < 0)
		{
			clearTimeout(nextTimeout);
		
			// server.close();
		
			process.exit(0);
		}
		else
		{
			count = 0;
			nextTimeout = setTimeout(test, 500);
		}
	}
}

