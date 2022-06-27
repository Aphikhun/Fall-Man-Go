local standards = ZBREQUIRE "luacheck.standards"

local empty = {}

local luajit_string_def = standards.def_fields("byte", "char", "dump", "find", "format", "gmatch",
   "gsub", "len", "lower", "match", "rep", "reverse", "sub", "upper")

-- Globals added by lua-nginx-module 0.10.10 in internal definition table format.
-- Will be added to `luajit` std to form `ngx_lua` std.
local ngx_defs = {
   fields = {
      ngx = {
         fields = {
            arg = {other_fields = true, read_only = false},
            var = {other_fields = true, read_only = false},
            OK = empty,
            ERROR = empty,
            AGAIN = empty,
            DONE = empty,
            DECLINED = empty,
            null = empty,
            HTTP_GET = empty,
            HTTP_HEAD = empty,
            HTTP_PUT = empty,
            HTTP_POST = empty,
            HTTP_DELETE = empty,
            HTTP_OPTIONS = empty,
            HTTP_MKCOL = empty,
            HTTP_COPY = empty,
            HTTP_MOVE = empty,
            HTTP_PROPFIND = empty,
            HTTP_PROPPATCH = empty,
            HTTP_LOCK = empty,
            HTTP_UNLOCK = empty,
            HTTP_PATCH = empty,
            HTTP_TRACE = empty,
            HTTP_CONTINUE = empty,
            HTTP_SWITCHING_PROTOCOLS = empty,
            HTTP_OK = empty,
            HTTP_CREATED = empty,
            HTTP_ACCEPTED = empty,
            HTTP_NO_CONTENT = empty,
            HTTP_PARTIAL_CONTENT = empty,
            HTTP_SPECIAL_RESPONSE = empty,
            HTTP_MOVED_PERMANENTLY = empty,
            HTTP_MOVED_TEMPORARILY = empty,
            HTTP_SEE_OTHER = empty,
            HTTP_NOT_MODIFIED = empty,
            HTTP_TEMPORARY_REDIRECT = empty,
            HTTP_BAD_REQUEST = empty,
            HTTP_UNAUTHORIZED = empty,
            HTTP_PAYMENT_REQUIRED = empty,
            HTTP_FORBIDDEN = empty,
            HTTP_NOT_FOUND = empty,
            HTTP_NOT_ALLOWED = empty,
            HTTP_NOT_ACCEPTABLE = empty,
            HTTP_REQUEST_TIMEOUT = empty,
            HTTP_CONFLICT = empty,
            HTTP_GONE = empty,
            HTTP_UPGRADE_REQUIRED = empty,
            HTTP_TOO_MANY_REQUESTS = empty,
            HTTP_CLOSE = empty,
            HTTP_ILLEGAL = empty,
            HTTP_INTERNAL_SERVER_ERROR = empty,
            HTTP_METHOD_NOT_IMPLEMENTED = empty,
            HTTP_BAD_GATEWAY = empty,
            HTTP_SERVICE_UNAVAILABLE = empty,
            HTTP_GATEWAY_TIMEOUT = empty,
            HTTP_VERSION_NOT_SUPPORTED = empty,
            HTTP_INSUFFICIENT_STORAGE = empty,
            STDERR = empty,
            EMERG = empty,
            ALERT = empty,
            CRIT = empty,
            ERR = empty,
            WARN = empty,
            NOTICE = empty,
            INFO = empty,
            DEBUG = empty,
            ctx = {other_fields = true, read_only = false},
            location = standards.def_fields("capture", "capture_multi"),
            status = {read_only = false},
            header = {other_fields = true, read_only = false},
            resp = standards.def_fields("get_headers"),
            req = standards.def_fields("is_internal", "start_time", "http_version", "raw_header",
               "get_method", "set_method", "set_uri", "set_uri_args", "get_uri_args",
               "get_post_args", "get_headers", "set_header", "clear_header", "read_body",
               "discard_body", "get_body_data", "get_body_file", "set_body_data",
               "set_body_file", "init_body", "append_body", "finish_body", "socket"),
            exec = empty,
            redirect = empty,
            send_headers = empty,
            headers_sent = empty,
            print = empty,
            say = empty,
            log = empty,
            flush = empty,
            exit = empty,
            eof = empty,
            sleep = empty,
            escape_uri = empty,
            unescape_uri = empty,
            encode_args = empty,
            decode_args = empty,
            encode_base64 = empty,
            decode_base64 = empty,
            crc32_short = empty,
            crc32_long = empty,
            hmac_sha1 = empty,
            md5 = empty,
            md5_bin = empty,
            sha1_bin = empty,
            quote_sql_str = empty,
            today = empty,
            time = empty,
            now = empty,
            update_time = empty,
            localtime = empty,
            utctime = empty,
            cookie_time = empty,
            http_time = empty,
            parse_http_time = empty,
            is_subrequest = empty,
            re = standards.def_fields("match", "find", "gmatch", "sub", "gsub"),
            shared = {other_fields = true, read_only = false},
            socket = standards.def_fields("udp", "tcp", "connect", "stream"),
            get_phase = empty,
            thread = standards.def_fields("spawn", "wait", "kill"),
            on_abort = empty,
            timer = standards.def_fields("at", "every", "running_count", "pending_count"),
            config = {
               fields = {
                  subsystem = luajit_string_def,
                  debug = empty,
                  prefix = empty,
                  nginx_version = empty,
                  nginx_configure = empty,
                  ngx_lua_version = empty,
               }
            },
            worker = standards.def_fields("pid", "count", "id", "exiting"),
         },
      },
      ndk = {
         fields = {
            set_var = {other_fields = true},
         },
      },
   },
}

return ngx_defs
