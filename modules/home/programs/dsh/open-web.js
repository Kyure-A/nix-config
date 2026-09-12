// Open DSH's authenticated startup URL without placing its token in argv.
ObjC.import('Foundation');
ObjC.import('AppKit');
function run(argv) {
  const data = $.NSString.stringWithContentsOfFileEncodingError(
    argv[0], $.NSUTF8StringEncoding, null);
  if (!data) throw new Error('DSH has not written its startup log yet.');
  const urls = ObjC.unwrap(data).split('\n')
    .filter(line => line.startsWith('dsh web: http://127.0.0.1:3080/?token='));
  if (!urls.length) throw new Error('DSH has not announced readiness yet.');
  const url = urls[urls.length - 1].slice('dsh web: '.length);
  if (!$.NSWorkspace.sharedWorkspace.openURL($.NSURL.URLWithString(url))) {
    throw new Error('Could not open the default browser.');
  }
}
