import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

import 'package:supabase/supabase.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = '0.0.0.0';

void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest);

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

Future<shelf.Response> _echoRequest(shelf.Request request) async{
  switch(request.url.toString()) {
    case 'users': return _echoUsers(request);
    default : return shelf.Response.ok('Invalid url');
  }
}

Future<shelf.Response> _echoUsers(shelf.Request request) async{
  final client = SupabaseClient('https://phrxhasexibmsuolzpxa.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTYzNjIwOTM4MCwiZXhwIjoxOTUxNzg1MzgwfQ.k1KrkZRvaz64EwQnCV1Rf5s8Jv-7ZAEcZ5enklYl3Os');

  final response =  await client
      .from('users')
      .select()
      .execute();

  var map = {
    'users' : response.data
  };

  return shelf.Response.ok(jsonEncode(map));
}
