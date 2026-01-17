/*
 * ⚙️ ESP32-S3 Nano Voice Client 설정 파일
 * 
 * ESP32-S3 Nano 보드 전용 핀 배치
 * 일반 DevKit과 핀이 다르므로 주의!
 * 
 * 보드 정보:
 * - ESP32-S3-WROOM-1 모듈
 * - USB-C 포트
 * - PSRAM 내장 (중요: 오디오 버퍼용)
 */

#ifndef CONFIG_H
#define CONFIG_H

// =====================================
// 🌐 WiFi 설정 (반드시 수정하세요!)
// =====================================
#define WIFI_SSID     "YourWiFiName"      // WiFi 이름
#define WIFI_PASSWORD "YourWiFiPassword"  // WiFi 비밀번호

// =====================================
// 🖥️ Raspberry Pi 서버 설정
// =====================================
#define SERVER_IP     "192.168.0.100"     // Raspberry Pi IP
#define SERVER_PORT   5000                // 서버 포트

// =====================================
// 📌 ESP32-S3 Nano 핀 배치
// =====================================
// 
//         ESP32-S3 Nano 보드 상단도
//         ┌─────────────────────┐
//    3.3V │●                   ●│ 5V (VBUS)
//     GND │●                   ●│ GND
//   GPIO1 │●                   ●│ GPIO2
//   GPIO3 │●                   ●│ GPIO4
//   GPIO5 │●                   ●│ GPIO6
//   GPIO7 │●                   ●│ GPIO8
//   GPIO9 │●                   ●│ GPIO10
//  GPIO11 │●                   ●│ GPIO12
//  GPIO13 │●                   ●│ GPIO14
//  GPIO15 │●      [USB-C]      ●│ GPIO16
//  GPIO17 │●                   ●│ GPIO18
//  GPIO21 │●                   ●│ GPIO35
//  GPIO36 │●                   ●│ GPIO37
//  GPIO38 │●                   ●│ GPIO39
//  GPIO40 │●                   ●│ GPIO41
//  GPIO42 │●                   ●│ GPIO47
//  GPIO48 │●                   ●│ GPIO0 (BOOT)
//         └─────────────────────┘
//
// =====================================

// =====================================
// 🎤 INMP441 마이크 핀 설정 (I2S RX)
// =====================================
// I2S0을 마이크 입력으로 사용
#define I2S_MIC_SERIAL_CLOCK   GPIO_NUM_4   // SCK (비트 클럭)
#define I2S_MIC_LEFT_RIGHT_CLOCK GPIO_NUM_5 // WS (워드 선택)
#define I2S_MIC_SERIAL_DATA    GPIO_NUM_6   // SD (데이터)

// =====================================
// 🔊 MAX98357A 스피커 핀 설정 (I2S TX)
// =====================================
// I2S1을 스피커 출력으로 사용
#define I2S_SPK_SERIAL_CLOCK   GPIO_NUM_7   // BCLK (비트 클럭)
#define I2S_SPK_LEFT_RIGHT_CLOCK GPIO_NUM_15 // LRC (좌우 클럭)
#define I2S_SPK_SERIAL_DATA    GPIO_NUM_16  // DIN (데이터)

// =====================================
// 📺 GC9A01 LCD 핀 설정 (SPI)
// =====================================
// HSPI 사용
#define TFT_MOSI     GPIO_NUM_11   // SDA (데이터)
#define TFT_SCLK     GPIO_NUM_12   // SCL (클럭)
#define TFT_CS       GPIO_NUM_10   // CS (칩 선택)
#define TFT_DC       GPIO_NUM_13   // DC (데이터/명령)
#define TFT_RST      GPIO_NUM_14   // RST (리셋)
#define TFT_BL       GPIO_NUM_21   // BL (백라이트, 선택사항)

// =====================================
// 🔘 버튼 설정
// =====================================
#define BUTTON_PIN   GPIO_NUM_0    // BOOT 버튼 사용

// =====================================
// 🎵 오디오 설정
// =====================================
#define SAMPLE_RATE   16000   // 16kHz (음성인식에 최적)
#define SAMPLE_BITS   16      // 16비트
#define CHANNELS      1       // 모노
#define RECORD_SECONDS 5      // 최대 녹음 시간

// 버퍼 크기 (bytes)
// = 샘플레이트 × 시간 × (비트/8) × 채널
// = 16000 × 5 × 2 × 1 = 160,000 bytes
#define AUDIO_BUFFER_SIZE (SAMPLE_RATE * RECORD_SECONDS * (SAMPLE_BITS / 8) * CHANNELS)

// =====================================
// 📺 LCD 설정
// =====================================
#define LCD_WIDTH    240
#define LCD_HEIGHT   240

// =====================================
// 🕐 타이밍 설정
// =====================================
#define DEBOUNCE_MS      50     // 버튼 디바운스
#define SERVER_TIMEOUT   30000  // 서버 응답 대기 (ms)
#define WIFI_TIMEOUT     20000  // WiFi 연결 대기 (ms)

#endif // CONFIG_H
