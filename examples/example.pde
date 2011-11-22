#include <NewSoftSerial.h>
#include <bson.h>

NewSoftSerial mySerial(5,4);

char* buffer;
int bufferIndex;
boolean gotData;

int serial_printf(const char *fmt, ... ){
  char tmp[256]; // resulting string limited to 128 chars
  va_list args;
  va_start (args, fmt );
  int result = vsnprintf(tmp, 256, fmt, args);
  va_end (args);
  Serial.print(tmp);
  return result;
}

int serial_fprintf(FILE * stream, const char *format, ...) {
  return 0;  
}

void bson_example() {
    bson b, sub;
    bson_iterator it;

    /* Create a rich document like this one:
     *
     * { _id: ObjectId("4d95ea712b752328eb2fc2cc"),
     *   user_id: ObjectId("4d95ea712b752328eb2fc2cd"),
     *
     *   items: [
     *     { sku: "col-123",
     *       name: "John Coltrane: Impressions",
     *       price: 1099,
     *     },
     *
     *     { sku: "young-456",
     *       name: "Larry Young: Unity",
     *       price: 1199
     *     }
     *   ],
     *
     *   address: {
     *     street: "59 18th St.",
     *     zip: 10010
     *   },
     *
     *   total: 2298
     * }
     */
    bson_init( &b );
    bson_append_new_oid( &b, "_id" );
    bson_append_new_oid( &b, "user_id" );

    bson_append_start_array( &b, "items" );
    bson_append_start_object( &b, "0" );
    bson_append_string( &b, "name", "John Coltrane: Impressions" );
    bson_append_int( &b, "price", 1099 );
    bson_append_finish_object( &b );

    bson_append_start_object( &b, "1" );
    bson_append_string( &b, "name", "Larry Young: Unity" );
    bson_append_int( &b, "price", 1199 );
    bson_append_finish_object( &b );
    bson_append_finish_object( &b );

    bson_append_start_object( &b, "address" );
    bson_append_string( &b, "street", "59 18th St." );
    bson_append_int( &b, "zip", 10010 );
    bson_append_finish_object( &b );

    bson_append_int( &b, "total", 2298 );

    bson_finish( &b );

    /* Advance to the 'items' array */
    bson_find( &it, &b, "items" );

    /* Get the subobject representing items */
    bson_iterator_subobject( &it, &sub );

    /* Now iterate that object */
    bson_print( &sub );
}

void setup()  
{
  bson_set_printf(serial_printf);
  bson_set_fprintf(serial_fprintf);
  
  Serial.begin(115200);

  bson_example();  
}  
  
void loop()                     // run over and over again
{

  if(Serial.available()) {
    if(buffer == NULL) {
      buffer = (char *)malloc(1024 * sizeof(char));
    }
    buffer[bufferIndex] = Serial.read();
    bufferIndex++;
    gotData = true;
  } else if(gotData) {
    Serial.println("Printing BSON!");
    bufferIndex = 0;
    bson b;
    int initStatus = bson_init_data(&b, buffer);
      if(initStatus == BSON_OK) {
      Serial.println("Valid BSON Data!");
      bson_print(&b);
    } else {
      Serial.println("Invalid BSON Data!");
    }
    free(buffer);
    buffer = NULL;
    gotData = false;
  }
  
  delay(1);
}
