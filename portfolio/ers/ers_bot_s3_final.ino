/*
  XIAO ESP32S3 Sense (camera) -> ESP-NOW sender
  QR payload format: integer 1..52 (ASCII, e.g. "17")

  Sends 1 byte: card_id (1..52)
*/

#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>

#include <ESP32QRCodeReader.h>
#include "esp_camera.h"

// ----------------------------
// 1) Paste receiver MAC here
// ----------------------------
static uint8_t RECEIVER_MAC[6] = { 0xE4, 0xB3, 0x23, 0xC4, 0x53, 0xAC };

// ----------------------------
// 2) ESP-NOW radio channel
// ----------------------------
static const uint8_t ESPNOW_CHANNEL = 1;

// ----------------------------
// 3) Camera pins (XIAO ESP32S3 Sense camera connector)
// ----------------------------


ESP32QRCodeReader reader(CAMERA_MODEL_XIAO_ESP32S3_SENSE);

// ----------------------------
// 4) Payload (1 byte)
// ----------------------------
typedef struct __attribute__((packed)) {
  uint8_t card_id; // 1..52
} CardPacket;

// ----------------------------
// 5) Low-latency “new card” gating
// ----------------------------
static uint8_t lastSeen = 0;
static uint8_t stableCount = 0;
static uint8_t lastSent = 0;

static const uint8_t STABLE_REQUIRED = 1;     // set to 1 for absolute fastest
static uint32_t lockoutUntilMs = 0;
static const uint32_t SEND_LOCKOUT_MS = 150;  // short anti-spam

// ----------------------------
// 6) QR payload parsing: ASCII int 1..52 (no String, no heap)
// ----------------------------
static inline bool parseCardId_1to52(const char* p, uint8_t &out) {
  if (!p) return false;

  while (*p == ' ' || *p == '\n' || *p == '\r' || *p == '\t') p++;

  int v = 0;
  int digits = 0;
  while (*p >= '0' && *p <= '9') {
    v = v * 10 + (*p - '0');
    p++;
    digits++;
    if (digits > 2) return false;
  }

  while (*p == ' ' || *p == '\n' || *p == '\r' || *p == '\t') p++;
  if (*p != '\0') return false;

  if (v < 1 || v > 52) return false;
  out = (uint8_t)v;
  return true;
}

// ----------------------------
// 7) ESP-NOW send callback (ESP32 core 3.x signature)
// ----------------------------
static void onEspNowSent(const wifi_tx_info_t *tx_info, esp_now_send_status_t status) {
  (void)tx_info;

  if (status == ESP_NOW_SEND_SUCCESS) {
    Serial.println("ESP-NOW: Send OK");
  } else {
    Serial.println("ESP-NOW: Send FAILED");
  }
}

// ----------------------------
// 8) ESP-NOW init
// ----------------------------
static bool initEspNow() {
  WiFi.mode(WIFI_STA);   // enables Wi-Fi radio; does NOT connect
  WiFi.setSleep(false);  // lower latency

  // Force fixed channel (receiver must match)
  esp_wifi_set_promiscuous(true);
  esp_wifi_set_channel(ESPNOW_CHANNEL, WIFI_SECOND_CHAN_NONE);
  esp_wifi_set_promiscuous(false);

  if (esp_now_init() != ESP_OK) return false;

  // Optional; safe to remove entirely if you don’t care about send status
  esp_now_register_send_cb(onEspNowSent);

  esp_now_peer_info_t peer{};
  memcpy(peer.peer_addr, RECEIVER_MAC, 6);
  peer.channel = ESPNOW_CHANNEL;
  peer.encrypt = false;

  esp_now_del_peer(RECEIVER_MAC); // ignore result
  if (esp_now_add_peer(&peer) != ESP_OK) return false;

  return true;
}

// ----------------------------
// 9) Send function
// ----------------------------
static inline void sendCardId(uint8_t cardId) {
  CardPacket pkt{ .card_id = cardId };
  esp_now_send(RECEIVER_MAC, (uint8_t*)&pkt, sizeof(pkt));
}

void setup() {
  Serial.begin(115200);

  if (!initEspNow()) {
    Serial.println("ESP-NOW init failed");
    while (true) delay(1000);
  }

  reader.setDebug(false);

  auto err = reader.setup();
  
  if (err != SETUP_OK) {
    Serial.printf("QR setup failed: %d\n", (int)err);
    while (true) delay(1000);
  }

  // --- Your requested flip settings ---
  sensor_t *s = esp_camera_sensor_get();
  s->set_hmirror(s, 0);
  s->set_vflip(s, 1);

  reader.beginOnCore(1);

  Serial.println("Sender ready.");
}

void loop() {
  QRCodeData qr;
  if (reader.receiveQrCode(&qr, 10)) {
    if (!qr.valid) return;

    uint8_t id;
    if (!parseCardId_1to52((const char*)qr.payload, id)) return;

    if (id == lastSeen) stableCount++;
    else { lastSeen = id; stableCount = 1; }

    if (stableCount >= STABLE_REQUIRED) {
      uint32_t now = millis();
      if (now < lockoutUntilMs) return;

      if (id != lastSent) {
        lastSent = id;
        lockoutUntilMs = now + SEND_LOCKOUT_MS;

        Serial.printf("QR detected: Card ID = %u\n", id);

        sendCardId(id);
      }
    }
  }
}
