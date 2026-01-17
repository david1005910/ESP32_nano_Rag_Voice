/*
 * =====================================
 * 📺 TFT_eSPI 설정 가이드
 * ESP32-S3 Nano + GC9A01 1.28" LCD
 * =====================================
 *
 * TFT_eSPI 라이브러리의 User_Setup.h 파일을 수정해야 합니다.
 *
 * 📁 파일 위치:
 * - Windows: C:\Users\[사용자]\Documents\Arduino\libraries\TFT_eSPI\User_Setup.h
 * - Mac: ~/Documents/Arduino/libraries/TFT_eSPI/User_Setup.h  
 * - Linux: ~/Arduino/libraries/TFT_eSPI/User_Setup.h
 *
 * ⚠️ 중요: 기존 설정을 모두 주석 처리하고 아래 내용을 추가하세요!
 */

// =====================================
// User_Setup.h에 복사할 내용 시작
// =====================================

// GC9A01 드라이버 선택
#define GC9A01_DRIVER

// 화면 크기
#define TFT_WIDTH  240
#define TFT_HEIGHT 240

// ESP32-S3 Nano 핀 설정
#define TFT_MOSI 11    // SDA (데이터)
#define TFT_SCLK 12    // SCL (클럭)
#define TFT_CS   10    // CS (칩 선택)
#define TFT_DC   13    // DC (데이터/명령)
#define TFT_RST  14    // RST (리셋)

// 백라이트 (선택사항)
// #define TFT_BL   21

// SPI 속도 (40MHz)
#define SPI_FREQUENCY  40000000

// 폰트 로드
#define LOAD_GLCD
#define LOAD_FONT2
#define LOAD_FONT4
#define LOAD_FONT6
#define LOAD_FONT7
#define LOAD_FONT8
#define LOAD_GFXFF

// 부드러운 폰트
#define SMOOTH_FONT

// =====================================
// User_Setup.h에 복사할 내용 끝
// =====================================

/*
 * 📋 설정 방법 요약:
 * 
 * 1. Arduino 라이브러리 관리자에서 TFT_eSPI 설치
 * 
 * 2. 위 파일 경로에서 User_Setup.h 열기
 * 
 * 3. 기존 내용 전체를 주석 처리 (Ctrl+A → 각 줄 앞에 // 추가)
 *    또는 기존 파일 백업 후 내용 교체
 * 
 * 4. 위의 설정 내용을 파일에 붙여넣기
 * 
 * 5. 저장 후 Arduino IDE 재시작
 * 
 * 6. 예제 실행: 파일 → 예제 → TFT_eSPI → Generic → Colour_Test
 *    화면에 색상이 표시되면 성공!
 */

/*
 * ⚠️ 흔한 문제 해결:
 * 
 * Q: 화면이 안 켜져요
 * A: - 전원 연결 확인 (VCC → 3.3V)
 *    - 핀 연결 재확인
 *    - User_Setup.h가 저장되었는지 확인
 * 
 * Q: 화면이 깨져서 보여요
 * A: - 드라이버가 GC9A01_DRIVER로 설정되었는지 확인
 *    - SPI 속도를 낮춰보기 (20000000)
 * 
 * Q: 색상이 이상해요
 * A: - GC9A01_DRIVER 설정 확인
 *    - tft.setRotation(0) 값 변경해보기 (0~3)
 */
