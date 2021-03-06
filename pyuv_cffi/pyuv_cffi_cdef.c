typedef enum {
    UV_RUN_DEFAULT = 0,
    UV_RUN_ONCE,
    UV_RUN_NOWAIT
} uv_run_mode;

enum uv_poll_event {
    UV_READABLE = 1,
    UV_WRITABLE = 2
};

// handle structs and types
struct uv_loop_s {...;};
struct uv_handle_s {void *data; ...;};
struct uv_idle_s {...;};
struct uv_prepare_s {...;};
struct uv_timer_s {...;};
struct uv_signal_s {...;};
struct uv_poll_s {...;};
struct uv_check_s {...;};
struct uv_pipe_s {...;};
struct uv_fs_event_s {...;};

typedef struct uv_loop_s uv_loop_t;
typedef struct uv_handle_s uv_handle_t;
typedef struct uv_idle_s uv_idle_t;
typedef struct uv_prepare_s uv_prepare_t;
typedef struct uv_timer_s uv_timer_t;
typedef struct uv_signal_s uv_signal_t;
typedef struct uv_poll_s uv_poll_t;
typedef struct uv_check_s uv_check_t;
typedef struct uv_pipe_s uv_pipe_t;
typedef struct uv_fs_event_s uv_fs_event_t;

typedef void (*uv_walk_cb)(uv_handle_t *handle, void *arg);
typedef void (*uv_close_cb)(uv_handle_t *handle);
typedef void (*uv_idle_cb)(uv_idle_t *handle);
typedef void (*uv_prepare_cb)(uv_prepare_t *handle);
typedef void (*uv_poll_cb)(uv_poll_t *handle, int status, int events);
typedef void (*uv_timer_cb)(uv_timer_t *handle);
typedef void (*uv_signal_cb)(uv_signal_t *handle, int signum);
typedef void (*uv_check_cb)(uv_check_t* handle);
typedef void (*uv_fs_event_cb)(uv_fs_event_t* handle, const char* filename, int events, int status);

// loop functions
uv_loop_t *uv_default_loop();
int uv_loop_init(uv_loop_t* loop);
int uv_loop_alive(const uv_loop_t *loop);
int uv_run(uv_loop_t *, uv_run_mode mode);
uint64_t uv_now(const uv_loop_t* loop);
void uv_stop(uv_loop_t *);
void uv_walk(uv_loop_t *loop, uv_walk_cb walk_cb, void *arg);

// handle functions
// uv_handle_t is the base type for all libuv handle types.
uv_handle_t *cast_handle(void *handle);
void uv_ref(uv_handle_t *);
void uv_unref(uv_handle_t *);
int uv_has_ref(const uv_handle_t *);
void uv_close(uv_handle_t *handle, uv_close_cb close_cb);
int uv_is_active(const uv_handle_t *handle);
int uv_is_closing(const uv_handle_t *handle);

// idle functions
// Idle handles will run the given callback once per loop iteration, right
// before the uv_prepare_t handles. Note: The notable difference with prepare
// handles is that when there are active idle handles, the loop will perform a
// zero timeout poll instead of blocking for i/o. Warning: Despite the name,
// idle handles will get their callbacks called on every loop iteration, not
// when the loop is actually "idle".
int uv_idle_init(uv_loop_t *, uv_idle_t *idle);
int uv_idle_start(uv_idle_t *idle, uv_idle_cb cb);
int uv_idle_stop(uv_idle_t *idle);

// prepare functions
// Prepare handles will run the given callback once per loop iteration, right
// before polling for i/o.
int uv_prepare_init(uv_loop_t *, uv_prepare_t *prepare);
int uv_prepare_start(uv_prepare_t *prepare, uv_prepare_cb cb);
int uv_prepare_stop(uv_prepare_t *prepare);

// check functions
// Check handles will run the given callback once per loop iteration, right
int uv_check_init(uv_loop_t *, uv_check_t *check);
int uv_check_start(uv_check_t *check, uv_check_cb cb);
int uv_check_stop(uv_check_t *check);

// timer functions
// Timer handles are used to schedule callbacks to be called in the future.
int uv_timer_init(uv_loop_t *, uv_timer_t *handle);
int uv_timer_start(uv_timer_t *handle, uv_timer_cb cb, uint64_t timeout, uint64_t repeat);
int uv_timer_stop(uv_timer_t *handle);
int uv_timer_again(uv_timer_t *handle);
void uv_timer_set_repeat(uv_timer_t *handle, uint64_t repeat);
uint64_t uv_timer_get_repeat(const uv_timer_t *handle);

// signal functions
// Signal handles implement Unix style signal handling on a per-event loop
// bases.
int uv_signal_init(uv_loop_t *loop, uv_signal_t *handle);
int uv_signal_start(uv_signal_t *handle, uv_signal_cb signal_cb, int signum);
int uv_signal_stop(uv_signal_t *handle);

// poll functions
// Poll handles are used to watch file descriptors for readability and
// writability, similar to the purpose of poll(2). It is not okay to have
// multiple active poll handles for the same socket, this can cause libuv to
// busyloop or otherwise malfunction.
int uv_poll_init(uv_loop_t *loop, uv_poll_t *handle, int fd);
int uv_poll_start(uv_poll_t *handle, int events, uv_poll_cb cb);
int uv_poll_stop(uv_poll_t *handle);

// process functions
void uv_disable_stdio_inheritance(void);

// pipe functions
int uv_pipe_init(uv_loop_t *loop, uv_pipe_t *pipe, int ipc);

//fs_event functions
int uv_fs_event_init(uv_loop_t* loop, uv_fs_event_t* handle);
int uv_fs_event_start(uv_fs_event_t* handle, uv_fs_event_cb cb, const char* path,
                      unsigned int flags);
