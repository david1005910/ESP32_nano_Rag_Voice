/*
 * 🎤 ESP32-S3 Nano Voice RAG Client
 * 
 * ESP32-S3 Nano + GC9A01 LCD + INMP441 마이크 + MAX98357A 스피커
 * 
 * 작동 방식:
 * 1. BOOT 버튼을 누르면 녹음 시작
 * 2. 버튼을 놓으면 녹음 종료 → 서버로 전송
 * 3. 서버에서 AI 응답 수신
 * 4. 스피커로 응답 재생
 * 
 * 필요한 라이브러리:
 * - TFT_eSPI (LCD)
 * - ArduinoJson
 * - ESP32 보드 패키지 (2.0.0 이상)
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <driver/i2s.h>
#include <TFT_eSPI.h>
#include <ArduinoJson.h>
#include "config.h"

// =====================================
// 📺 LCD 객체
// =====================================
TFT_eSPI tft = TFT_eSPI();
TFT_eSprite sprite = TFT_eSprite(&tft);  // 더블 버퍼링용

// =====================================
// 🎵 오디오 버퍼 (PSRAM 사용)
// =====================================
uint8_t* audioBuffer = nullptr;
size_t audioBufferPos = 0;

// =====================================
// 📊 상태 관리
// =====================================
enum SystemState {
    STATE_INIT,         // 초기화 중
    STATE_CONNECTING,   // WiFi 연결 중
    STATE_READY,        // 준비 완료 (대기)
    STATE_RECORDING,    // 녹음 중
    STATE_SENDING,      // 서버로 전송 중
    STATE_PROCESSING,   // AI 처리 중
    STATE_PLAYING,      // 응답 재생 중
    STATE_ERROR         // 에러 발생
};

SystemState currentState = STATE_INIT;
String lastError = "";

// =====================================
// 🔘 버튼 상태
// =====================================
volatile bool buttonPressed = false;
volatile unsigned long lastButtonPress = 0;

// 인터럽트 핸들러
void IRAM_ATTR buttonISR() {
    unsigned long now = millis();
    if (now - lastButtonPress > DEBOUNCE_MS) {
        buttonPressed = true;
        lastButtonPress = now;
    }
}

// =====================================
// 🎨 색상 정의
// =====================================
#define COLOR_BG        TFT_BLACK
#define COLOR_TEXT      TFT_WHITE
#define COLOR_READY     0x07E0  // 녹색
#define COLOR_RECORDING 0xF800  // 빨간색
#define COLOR_SENDING   0xFD20  // 주황색
#define COLOR_PLAYING   0x001F  // 파란색
#define COLOR_ERROR     0xF800  // 빨간색

// =====================================
// 📺 LCD 화면 그리기 함수들
// =====================================

// 원형 프로그레스 표시
void drawCircularProgress(int percentage, uint16_t color) {
    int centerX = LCD_WIDTH / 2;
    int centerY = LCD_HEIGHT / 2;
    int radius = 100;
    
    // 배경 원
    tft.drawCircle(centerX, centerY, radius, TFT_DARKGREY);
    
    // 진행률 호
    if (percentage > 0) {
        int endAngle = map(percentage, 0, 100, 0, 360);
        for (int i = 0; i < endAngle; i++) {
            float rad = (i - 90) * PI / 180;
            int x = centerX + radius * cos(rad);
            int y = centerY + radius * sin(rad);
            tft.drawPixel(x, y, color);
            // 두께 추가
            tft.drawPixel(x+1, y, color);
            tft.drawPixel(x, y+1, color);
        }
    }
}

// 상태 화면 표시
void displayState(const char* title, const char* subtitle, uint16_t color) {
    tft.fillScreen(COLOR_BG);
    
    // 상단 상태 원
    tft.fillCircle(LCD_WIDTH/2, 70, 40, color);
    
    // 제목
    tft.setTextColor(COLOR_TEXT);
    tft.setTextSize(2);
    tft.setTextDatum(MC_DATUM);
    tft.drawString(title, LCD_WIDTH/2, 140);
    
    // 부제목
    tft.setTextSize(1);
    tft.setTextColor(TFT_LIGHTGREY);
    tft.drawString(subtitle, LCD_WIDTH/2, 170);
}

// 초기화 화면
void displayInit() {
    tft.fillScreen(COLOR_BG);
    tft.setTextColor(COLOR_TEXT);
    tft.setTextSize(2);
    tft.setTextDatum(MC_DATUM);
    tft.drawString("Voice RAG", LCD_WIDTH/2, 100);
    tft.setTextSize(1);
    tft.drawString("Initializing...", LCD_WIDTH/2, 140);
}

// WiFi 연결 화면
void displayConnecting(int progress) {
    tft.fillScreen(COLOR_BG);
    
    // WiFi 아이콘 (간단한 호 3개)
    int cx = LCD_WIDTH / 2;
    int cy = 80;
    for (int i = 1; i <= 3; i++) {
        int r = i * 15;
        tft.drawArc(cx, cy, r, r-3, 225, 315, TFT_CYAN, COLOR_BG);
    }
    tft.fillCircle(cx, cy, 5, TFT_CYAN);
    
    tft.setTextColor(COLOR_TEXT);
    tft.setTextSize(2);
    tft.setTextDatum(MC_DATUM);
    tft.drawString("Connecting", LCD_WIDTH/2, 140);
    
    // 프로그레스 바
    int barWidth = 160;
    int barHeight = 8;
    int barX = (LCD_WIDTH - barWidth) / 2;
    int barY = 170;
    
    tft.drawRect(barX, barY, barWidth, barHeight, TFT_DARKGREY);
    tft.fillRect(barX + 2, barY + 2, (barWidth - 4) * progress / 100, barHeight - 4, TFT_CYAN);
}

// 준비 완료 화면
void displayReady() {
    tft.fillScreen(COLOR_BG);
    
    // 마이크 아이콘
    int cx = LCD_WIDTH / 2;
    int cy = 80;
    tft.fillRoundRect(cx - 15, cy - 30, 30, 50, 15, COLOR_READY);
    tft.fillRect(cx - 20, cy + 25, 40, 5, COLOR_READY);
    tft.fillRect(cx - 3, cy + 30, 6, 15, COLOR_READY);
    
    tft.setTextColor(COLOR_TEXT);
    tft.setTextSize(2);
    tft.setTextDatum(MC_DATUM);
    tft.drawString("Ready", LCD_WIDTH/2, 150);
    
    tft.setTextSize(1);
    tft.setTextColor(TFT_LIGHTGREY);
    tft.drawString("Press button to speak", LCD_WIDTH/2, 180);
}

// 녹음 중 화면
void displayRecording(int seconds) {
    tft.fillScreen(COLOR_BG);
    
    // 녹음 아이콘 (빨간 원)
    tft.fillCircle(LCD_WIDTH/2, 70, 35, COLOR_RECORDING);
    
    // 녹음 시간 표시
    tft.setTextColor(COLOR_TEXT);
    tft.setTextSize(3);
    tft.setTextDatum(MC_DATUM);
    char timeStr[10];
    sprintf(timeStr, "%d", seconds);
    tft.drawString(timeStr, LCD_WIDTH/2, 140);
    
    tft.setTextSize(1);
    tft.setTextColor(TFT_LIGHTGREY);
    tft.drawString("Recording... Release to stop", LCD_WIDTH/2, 180);
}

// 전송 중 화면
void displaySending() {
    displayState("Sending", "Please wait...", COLOR_SENDING);
}

// 처리 중 화면
void displayProcessing() {
    displayState("Processing", "AI is thinking...", COLOR_SENDING);
}

// 재생 중 화면
void displayPlaying() {
    tft.fillScreen(COLOR_BG);
    
    // 스피커 아이콘
    int cx = LCD_WIDTH / 2;
    int cy = 80;
    tft.fillRect(cx - 20, cy - 15, 20, 30, COLOR_PLAYING);
    tft.fillTriangle(cx, cy - 25, cx, cy + 25, cx + 30, cy, COLOR_PLAYING);
    
    // 음파
    for (int i = 1; i <= 3; i++) {
        tft.drawArc(cx + 35, cy, i * 12, i * 12 - 3, 315, 45, COLOR_PLAYING, COLOR_BG);
    }
    
    tft.setTextColor(COLOR_TEXT);
    tft.setTextSize(2);
    tft.setTextDatum(MC_DATUM);
    tft.drawString("Playing", LCD_WIDTH/2, 150);
}

// 에러 화면
void displayError(const char* message) {
    tft.fillScreen(COLOR_BG);
    
    // X 아이콘
    int cx = LCD_WIDTH / 2;
    int cy = 70;
    tft.drawLine(cx - 25, cy - 25, cx + 25, cy + 25, COLOR_ERROR);
    tft.drawLine(cx + 25, cy - 25, cx - 25, cy + 25, COLOR_ERROR);
    tft.drawLine(cx - 24, cy - 25, cx + 26, cy + 25, COLOR_ERROR);
    tft.drawLine(cx + 26, cy - 25, cx - 24, cy + 25, COLOR_ERROR);
    
    tft.setTextColor(COLOR_ERROR);
    tft.setTextSize(2);
    tft.setTextDatum(MC_DATUM);
    tft.drawString("Error", LCD_WIDTH/2, 130);
    
    tft.setTextSize(1);
    tft.setTextColor(TFT_LIGHTGREY);
    tft.drawString(message, LCD_WIDTH/2, 160);
    tft.drawString("Press button to retry", LCD_WIDTH/2, 190);
}

// =====================================
// 🎤 I2S 마이크 설정
// =====================================
void setupMicrophone() {
    Serial.println("Setting up microphone...");
    
    i2s_config_t i2s_config = {
        .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
        .sample_rate = SAMPLE_RATE,
        .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
        .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
        .communication_format = I2S_COMM_FORMAT_STAND_I2S,
        .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
        .dma_buf_count = 8,
        .dma_buf_len = 1024,
        .use_apll = false,
        .tx_desc_auto_clear = false,
        .fixed_mclk = 0
    };
    
    i2s_pin_config_t pin_config = {
        .bck_io_num = I2S_MIC_SERIAL_CLOCK,
        .ws_io_num = I2S_MIC_LEFT_RIGHT_CLOCK,
        .data_out_num = I2S_PIN_NO_CHANGE,
        .data_in_num = I2S_MIC_SERIAL_DATA
    };
    
    ESP_ERROR_CHECK(i2s_driver_install(I2S_NUM_0, &i2s_config, 0, NULL));
    ESP_ERROR_CHECK(i2s_set_pin(I2S_NUM_0, &pin_config));
    
    Serial.println("Microphone ready!");
}

// =====================================
// 🔊 I2S 스피커 설정
// =====================================
void setupSpeaker() {
    Serial.println("Setting up speaker...");
    
    i2s_config_t i2s_config = {
        .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX),
        .sample_rate = SAMPLE_RATE,
        .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
        .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
        .communication_format = I2S_COMM_FORMAT_STAND_I2S,
        .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
        .dma_buf_count = 8,
        .dma_buf_len = 1024,
        .use_apll = false,
        .tx_desc_auto_clear = true,
        .fixed_mclk = 0
    };
    
    i2s_pin_config_t pin_config = {
        .bck_io_num = I2S_SPK_SERIAL_CLOCK,
        .ws_io_num = I2S_SPK_LEFT_RIGHT_CLOCK,
        .data_out_num = I2S_SPK_SERIAL_DATA,
        .data_in_num = I2S_PIN_NO_CHANGE
    };
    
    ESP_ERROR_CHECK(i2s_driver_install(I2S_NUM_1, &i2s_config, 0, NULL));
    ESP_ERROR_CHECK(i2s_set_pin(I2S_NUM_1, &pin_config));
    
    Serial.println("Speaker ready!");
}

// =====================================
// 🌐 WiFi 연결
// =====================================
bool connectWiFi() {
    Serial.println("Connecting to WiFi...");
    currentState = STATE_CONNECTING;
    
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    int attempts = 0;
    int maxAttempts = WIFI_TIMEOUT / 500;
    
    while (WiFi.status() != WL_CONNECTED && attempts < maxAttempts) {
        delay(500);
        Serial.print(".");
        displayConnecting((attempts * 100) / maxAttempts);
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi connected!");
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());
        return true;
    } else {
        Serial.println("\nWiFi connection failed!");
        lastError = "WiFi failed";
        currentState = STATE_ERROR;
        displayError("WiFi connection failed");
        return false;
    }
}

// =====================================
// 🎙️ 음성 녹음
// =====================================
void recordAudio() {
    Serial.println("Recording started...");
    currentState = STATE_RECORDING;
    audioBufferPos = 0;
    
    unsigned long startTime = millis();
    unsigned long lastDisplayUpdate = 0;
    int16_t samples[512];
    size_t bytesRead;
    
    // 버튼이 눌려있는 동안 녹음
    while (digitalRead(BUTTON_PIN) == LOW) {
        // 최대 시간 체크
        unsigned long elapsed = millis() - startTime;
        if (elapsed > RECORD_SECONDS * 1000) {
            Serial.println("Max recording time reached");
            break;
        }
        
        // 마이크에서 읽기
        esp_err_t result = i2s_read(I2S_NUM_0, samples, sizeof(samples), &bytesRead, portMAX_DELAY);
        
        if (result == ESP_OK && bytesRead > 0) {
            // 버퍼에 저장
            if (audioBufferPos + bytesRead < AUDIO_BUFFER_SIZE) {
                memcpy(audioBuffer + audioBufferPos, samples, bytesRead);
                audioBufferPos += bytesRead;
            }
        }
        
        // 화면 업데이트 (500ms마다)
        if (millis() - lastDisplayUpdate > 500) {
            displayRecording(elapsed / 1000);
            lastDisplayUpdate = millis();
        }
    }
    
    Serial.printf("Recording complete: %d bytes\n", audioBufferPos);
}

// =====================================
// 📤 서버로 음성 전송 및 응답 수신
// =====================================
bool sendAndReceive() {
    if (audioBufferPos < 1000) {
        Serial.println("Recording too short");
        lastError = "Recording too short";
        return false;
    }
    
    Serial.println("Sending to server...");
    currentState = STATE_SENDING;
    displaySending();
    
    HTTPClient http;
    String url = String("http://") + SERVER_IP + ":" + SERVER_PORT + "/voice";
    
    http.begin(url);
    http.addHeader("Content-Type", "application/octet-stream");
    http.setTimeout(SERVER_TIMEOUT);
    
    int httpCode = http.POST(audioBuffer, audioBufferPos);
    
    if (httpCode == HTTP_CODE_OK) {
        Serial.println("Response received!");
        currentState = STATE_PROCESSING;
        displayProcessing();
        
        // 응답을 오디오 버퍼에 저장
        WiFiClient* stream = http.getStreamPtr();
        audioBufferPos = 0;
        
        while (stream->available() || http.connected()) {
            if (stream->available()) {
                size_t available = stream->available();
                size_t toRead = min(available, (size_t)(AUDIO_BUFFER_SIZE - audioBufferPos));
                if (toRead > 0) {
                    stream->readBytes(audioBuffer + audioBufferPos, toRead);
                    audioBufferPos += toRead;
                }
            }
            delay(1);
        }
        
        http.end();
        Serial.printf("Received %d bytes of audio\n", audioBufferPos);
        return true;
    } else {
        Serial.printf("HTTP error: %d\n", httpCode);
        lastError = "Server error: " + String(httpCode);
        http.end();
        return false;
    }
}

// =====================================
// 🔊 응답 재생
// =====================================
void playAudio() {
    if (audioBufferPos < 100) {
        Serial.println("No audio to play");
        return;
    }
    
    Serial.println("Playing response...");
    currentState = STATE_PLAYING;
    displayPlaying();
    
    // WAV 헤더 스킵 (44 bytes)
    size_t dataStart = 44;
    if (audioBufferPos <= dataStart) {
        dataStart = 0;
    }
    
    size_t position = dataStart;
    size_t bytesWritten;
    
    while (position < audioBufferPos) {
        size_t toWrite = min((size_t)1024, audioBufferPos - position);
        i2s_write(I2S_NUM_1, audioBuffer + position, toWrite, &bytesWritten, portMAX_DELAY);
        position += bytesWritten;
    }
    
    // 버퍼 비우기 (잔향 방지)
    i2s_zero_dma_buffer(I2S_NUM_1);
    
    Serial.println("Playback complete!");
}

// =====================================
// ⚙️ 초기 설정
// =====================================
void setup() {
    Serial.begin(115200);
    delay(1000);
    
    Serial.println("\n=============================");
    Serial.println("  ESP32-S3 Nano Voice RAG");
    Serial.println("=============================\n");
    
    // 버튼 설정
    pinMode(BUTTON_PIN, INPUT_PULLUP);
    attachInterrupt(digitalPinToInterrupt(BUTTON_PIN), buttonISR, FALLING);
    
    // LCD 초기화
    tft.init();
    tft.setRotation(0);
    tft.fillScreen(COLOR_BG);
    displayInit();
    
    // 오디오 버퍼 할당 (PSRAM 우선)
    if (psramFound()) {
        audioBuffer = (uint8_t*)ps_malloc(AUDIO_BUFFER_SIZE);
        Serial.println("Using PSRAM for audio buffer");
    } else {
        audioBuffer = (uint8_t*)malloc(AUDIO_BUFFER_SIZE);
        Serial.println("Using internal RAM for audio buffer");
    }
    
    if (!audioBuffer) {
        Serial.println("FATAL: Failed to allocate audio buffer!");
        displayError("Memory error");
        while(1) delay(1000);
    }
    Serial.printf("Audio buffer: %d bytes\n", AUDIO_BUFFER_SIZE);
    
    // I2S 설정
    setupMicrophone();
    setupSpeaker();
    
    // WiFi 연결
    if (!connectWiFi()) {
        return;
    }
    
    // 준비 완료
    currentState = STATE_READY;
    displayReady();
    Serial.println("\nSystem ready! Press BOOT button to start.");
}

// =====================================
// 🔄 메인 루프
// =====================================
void loop() {
    // WiFi 재연결
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi disconnected, reconnecting...");
        connectWiFi();
        if (WiFi.status() == WL_CONNECTED) {
            currentState = STATE_READY;
            displayReady();
        }
        return;
    }
    
    // 버튼 눌림 처리
    if (buttonPressed && currentState == STATE_READY) {
        buttonPressed = false;
        
        // 디바운스
        delay(DEBOUNCE_MS);
        if (digitalRead(BUTTON_PIN) == LOW) {
            // 녹음 시작
            recordAudio();
            
            // 서버 전송 및 응답 수신
            if (sendAndReceive()) {
                // 응답 재생
                playAudio();
            } else {
                currentState = STATE_ERROR;
                displayError(lastError.c_str());
                delay(3000);
            }
            
            // 준비 상태로 복귀
            currentState = STATE_READY;
            displayReady();
        }
    }
    
    // 에러 상태에서 버튼으로 복구
    if (buttonPressed && currentState == STATE_ERROR) {
        buttonPressed = false;
        delay(DEBOUNCE_MS);
        if (!connectWiFi()) {
            return;
        }
        currentState = STATE_READY;
        displayReady();
    }
    
    buttonPressed = false;
    delay(10);
}
