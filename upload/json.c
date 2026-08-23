#include <json-c/json.h>
#define _DEFAULT_SOURCE
#include <string.h>

char *SPECIAL_URL_KEY = "path";
char *SPECIAL_OUTPUT_URL_KEY = "path_part";
char *SPECIAL_SEPARATOR = "/";

int process_json(const char *json_str, char **output_str)
{
    json_object *json_obj = json_tokener_parse(json_str);
    if (!json_obj)
    {
        return 1;
    }
    json_object *output = json_object_new_object();
    json_object_object_add(output, "request_hash", json_object_new_string(json_str));
    json_object *array = json_object_new_array();

    json_object_object_foreach(json_obj, key, val)
    {
        if (strcmp(key, SPECIAL_URL_KEY) == 0)
        {
            // Split up the path into parts and add them to the output JSON
            const char *path = json_object_get_string(val);
            char *path_copy = strdup(path);
            char *next_part = strtok(path_copy, SPECIAL_SEPARATOR);
            while (next_part != NULL)
            {
                json_object *item = json_object_new_object();
                json_object_object_add(item, "part_type", json_object_new_string(SPECIAL_OUTPUT_URL_KEY));
                json_object_object_add(item, "data", json_object_new_string(next_part));
                json_object_array_add(array, item);
                next_part = strtok(NULL, SPECIAL_SEPARATOR);
            }
            free(path_copy);
        }
        else
        {
            json_object_get(val);
            json_object *item = json_object_new_object();
            json_object_object_add(item, "part_type", json_object_new_string(key));
            json_object_object_add(item, "data", val);
            json_object_array_add(array, item);
        }
    }

    json_object_object_add(output, "parts", array);

    *output_str = strdup(json_object_to_json_string(output));
    json_object_put(json_obj);
    json_object_put(output);
    return 0;
}
