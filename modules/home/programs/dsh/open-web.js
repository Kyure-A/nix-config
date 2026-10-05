// Open DSH's authenticated startup URL without placing its token in argv.
ObjC.import('Foundation');
ObjC.import('AppKit');
function run() {
  const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
  const url = ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding));
  if (!/^http:\/\/127\.0\.0\.1:3080\/\?token=[A-Za-z0-9_-]+$/.test(url)) {
    throw new Error('DSH did not supply a valid startup URL.');
  }
  if (!$.NSWorkspace.sharedWorkspace.openURL($.NSURL.URLWithString(url))) {
    throw new Error('Could not open the default browser.');
  }
}
