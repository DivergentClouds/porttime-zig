// Requires PortMidi
// https://github.com/PortMidi/portmidi/
//

const c = @cImport({
    @cInclude("porttime.h");
});


/// The function signature that `callback` takes in `start()`
pub const Callback = *const fn(a: i32, b: *anyopaque) callconv(.C) void;

// Do NOT make public, use errorCheck instead
const PtError = c.PtError;

/// Start the timer
/// `resolution` is how many ms it takes for the timer to advance
///
/// `callback` is a function that is called every time the timer advances
/// The callback must have the signature 
/// `fn(a: i32, b: *anyopaque) callconv(.C) void`
///
/// `user_data` is passed to the function specified by `callback`
///
/// The possible errors are:
/// PtAlreadyStarted and PtHostError
pub fn start(resolution: c_int, callback: ?Callback, user_data: *anyopaque) !void {
    const wrapper = struct {
        fn startCallback(a: i32, b: *anyopaque) callconv(.C) Callback {
            return callback.?();
        }
    };

    try errorCheck(
        c.Pt_Start(resolution, wrapper.startCallback, user_data)
    );
}

/// Stop the timer
///
/// The only possible error is PtAlreadyStopped 
pub fn stop() !void {
    try errorCheck(
        c.Pt_Stop()
    );
}

/// Returns `true` if the timer is running
pub fn started() bool {
    return c.Pt_Started() == 1;
}

/// Returns the time since the timer started in ms
pub fn time() i32 {
    return c.Pt_Time();
}

/// Pause the current thread
/// `duration` is the length of the pause in ms
/// The true duration of the pause may be rounded to the nearest
/// or next clock tick
pub fn sleep(duration: i32) void {
    c.Pt_Sleep(duration);
}

fn errorCheck(err: PtError) !void {
    switch (err) {
        c.ptNoError => return,
        c.ptHostError => return error.PtHostError,
        c.ptAlreadyStarted => return error.PtAlreadyStarted,
        c.ptAlreadyStopped => return error.PtAlreadyStopped,
        c.ptInsufficientMemory => return error.PtInsufficientMemory,
    }
}