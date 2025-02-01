#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <bson/bson.h>
#include <mongoc/mongoc.h>
#include "mongoose.h"

#define PORT "5001"

mongoc_client_t *client;
mongoc_collection_t *collection;

static void handle_request(struct mg_connection *c, int ev, void *ev_data, void *fn_data) {
    if (ev != MG_EV_HTTP_MSG) return;
    struct mg_http_message *hm = (struct mg_http_message *) ev_data;
    char response[4096];

    if (mg_http_match_uri(hm, "/posts")) {
        if (mg_vcasecmp(&hm->method, "GET") == 0) {
            bson_t *query = bson_new();
            mongoc_cursor_t *cursor = mongoc_collection_find_with_opts(collection, query, NULL, NULL);
            const bson_t *doc;
            char *json;
            strcpy(response, "[");
            int first = 1;
            while (mongoc_cursor_next(cursor, &doc)) {
                if (!first) strcat(response, ",");
                json = bson_as_json(doc, NULL);
                strcat(response, json);
                bson_free(json);
                first = 0;
            }
            strcat(response, "]");
            mongoc_cursor_destroy(cursor);
            bson_destroy(query);
            mg_http_reply(c, 200, "Content-Type: application/json\r\n", "%s", response);
        } else if (mg_vcasecmp(&hm->method, "POST") == 0) {
            bson_t *doc = bson_new();
            char user[100], content[500];
            mg_http_get_var(&hm->body, "user", user, sizeof(user));
            mg_http_get_var(&hm->body, "content", content, sizeof(content));

            if (strlen(user) == 0 || strlen(content) == 0) {
                mg_http_reply(c, 400, "Content-Type: application/json\r\n", "{\"error\":\"Missing user or content\"}");
                return;
            }

            bson_append_utf8(doc, "user", -1, user, -1);
            bson_append_utf8(doc, "content", -1, content, -1);
            bson_append_date_time(doc, "timestamp", -1, (int64_t) time(NULL) * 1000);

            if (!mongoc_collection_insert_one(collection, doc, NULL, NULL, NULL)) {
                bson_destroy(doc);
                mg_http_reply(c, 500, "Content-Type: application/json\r\n", "{\"error\":\"Failed to create post\"}");
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
    mongoc_init();
    client = mongoc_client_new("mongodb://localhost:27017");
    collection = mongoc_client_get_collection(client, "messageboard", "posts");

    struct mg_mgr mgr;
    mg_mgr_init(&mgr);
    mg_http_listen(&mgr, "http://0.0.0.0:" PORT, handle_request, NULL);

    printf("Server started on port %s\n", PORT);
    while (true) {
        mg_mgr_poll(&mgr, 1000);
    }

    mongoc_collection_destroy(collection);
    mongoc_client_destroy(client);
    mongoc_cleanup();
    mg_mgr_free(&mgr);
    return 0;
}
