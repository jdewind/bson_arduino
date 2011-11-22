#include <bson.h>

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

    /* Create a rich document like this one:
     *
     * {
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
     *   ]
     * }
     */
     
    bson b;
    
    bson_init( &b );

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

    bson_finish( &b );

    Serial.println("BSON Object:");
    bson_print( &b );
}

void setup()  
{
  bson_set_printf(serial_printf);
  bson_set_fprintf(serial_fprintf);
  
  Serial.begin(115200);

  bson_example();  
}  

char* buffer = NULL;
int bufferIndex = 0;
int bufferSize = 16;

void dynamically_allocate_buffer() {
  if(buffer == NULL) {
    buffer = (char *)malloc(bufferSize * sizeof(char));
  }
  
  if(bufferIndex == bufferSize) {
    char *tmp = buffer;
    buffer = (char *)malloc(bufferSize + 16 * sizeof(char));
    memcpy(buffer, tmp, bufferSize);
    bufferSize += 16;
    free(tmp);
  }
}

void reset_buffer() {
  free(buffer);
  char* buffer = NULL;
  int bufferIndex = 0;
  int bufferSize = 16;
}

void loop()                     // run over and over again
{

  if(Serial.available()) {
    dynamically_allocate_buffer();    
    buffer[bufferIndex] = Serial.read();
    bufferIndex++;
    gotData = true;
  } else if(gotData) {
    Serial.println("Printing BSON!");
    bufferIndex = 0;
    bson b;
    int initStatus = bson_init_data(&b, buffer);
      if(initStatus == BSON_OK) {
      bson_print(&b);
    } else {
      Serial.println("Invalid BSON Data!");
    }
    reset_buffer();
    gotData = false;
  }
  
  delay(1);
}
