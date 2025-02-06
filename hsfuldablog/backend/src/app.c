// backend/src/app.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <bson/bson.h>
#include <mongoc/mongoc.h>
#include "mongoose.h"

#define PORT "5001"

mongoc_client_t *client = NULL;
mongoc_collection_t *collection = NULL;

static void handle_request(struct mg_connection *c, int ev, void *ev_data, void *fn_data) {
    if (ev != MG_EV_HTTP_MSG) return;
    struct mg_http_message *hm = (struct mg_http_message *) ev_data;

    if (mg_http_match_uri(hm, "/posts")) {
        if (mg_vcasecmp(&hm->method, "GET") == 0) {
            bson_t *query = bson_new();
            mongoc_cursor_t *cursor = mongoc_collection_find_with_opts(collection, query, NULL, NULL);
            const bson_t *doc;
            char response[8192];
            size_t pos = 0;
            int first = 1;

            pos += snprintf(response + pos, sizeof(response) - pos, "[");
            while (mongoc_cursor_next(cursor, &doc)) {
                char *json = bson_as_json(doc, NULL);
                if (!first) {
                    pos += snprintf(response + pos, sizeof(response) - pos, ",");
                }
                pos += snprintf(response + pos, sizeof(response) - pos, "%s", json);
                bson_free(json);
                first = 0;
            }
            pos += snprintf(response + pos, sizeof(response) - pos, "]");
            mongoc_cursor_destroy(cursor);
            bson_destroy(query);
            mg_http_reply(c, 200, "Content-Type: application/json\r\n", "%s", response);
        } else if (mg_vcasecmp(&hm->method, "POST") == 0) {
            char user[100] = {0}, content[500] = {0};

            /* 
             * For production use a JSON parser.
             * Here we assume a POST body like:
             * {"user":"someuser","content":"sometext"}
             */
            if (sscanf(hm->body.ptr, "{\"user\":\"%99[^\"]\",\"content\":\"%499[^\"]\"}", user, content) != 2) {
                mg_http_reply(c, 400, "Content-Type: application/json\r\n", "{\"error\":\"Invalid JSON format\"}");
                return;
            }

            if (strlen(user) == 0 || strlen(content) == 0) {
                mg_http_reply(c, 400, "Content-Type: application/json\r\n", "{\"error\":\"Missing user or content\"}");
                return;
            }

            bson_t *doc = bson_new();
            bson_append_utf8(doc, "user", -1, user, -1);
            bson_append_utf8(doc, "content", -1, content, -1);
            bson_append_date_time(doc, "timestamp", -1, (int64_t) time(NULL) * 1000);

            bson_error_t error;
            if (!mongoc_collection_insert_one(collection, doc, NULL, NULL, &error)) {
                bson_destroy(doc);
                mg_http_reply(c, 500, "Content-Type: application/json\r\n", "{\"error\":\"Failed to create post: %s\"}", error.message);
                return;
            }
            bson_destroy(doc);
            mg_http_reply(c, 201, "Content-Type: application/json\r\n", "{\"message\":\"Post created!\"}");
        }
    } else {
        mg_http_reply(c, 404, "Content-Type: application/json\r\n", "{\"error\":\"Not Found\"}");
    }
}

int main(void) {
    const char *mongo_uri = getenv("MONGO_URI");
    if (!mongo_uri) {
        fprintf(stderr, "MONGO_URI environment variable not set.\n");
        return EXIT_FAILURE;
    }
    mongoc_init();
    client = mongoc_client_new(mongo_uri);
    if (!client) {
        fprintf(stderr, "Failed to create MongoDB client.\n");
        return EXIT_FAILURE;
    }
    collection = mongoc_client_get_collection(client, "messageboard", "posts");

    struct mg_mgr mgr;
    mg_mgr_init(&mgr);
    mg_http_listen(&mgr, "http://0.0.0.0:" PORT, handle_request, NULL);

    printf("Backend server started on port %s\n", PORT);
    for (;;) {
        mg_mgr_poll(&mgr, 1000);
    }

    mg_mgr_free(&mgr);
    mongoc_collection_destroy(collection);
    mongoc_client_destroy(client);
    mongoc_cleanup();
    return EXIT_SUCCESS;
}
