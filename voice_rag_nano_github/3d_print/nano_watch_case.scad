/*
 * 🕐 ESP32-S3 Nano Voice RAG 시계 케이스
 * 
 * 컴팩트한 Nano 보드에 맞춘 소형 시계 디자인
 * 
 * 부품:
 * - ESP32-S3 Nano (약 25.4mm x 48mm)
 * - GC9A01 1.28인치 원형 LCD (약 35mm)
 * - INMP441 마이크 (약 14mm x 10mm)
 * - MAX98357A 앰프 (약 17mm x 17mm)
 * - 소형 스피커 (20-23mm)
 * 
 * 인쇄 설정:
 * - 레이어: 0.2mm
 * - 인필: 20%
 * - 서포트: 케이스 본체에 필요
 */

// =====================================
// 📐 부품 치수 (단위: mm)
// =====================================

// ESP32-S3 Nano 보드
nano_length = 48;       // 길이
nano_width = 25.4;      // 너비 (약 1인치)
nano_height = 7;        // 높이 (부품 포함)
nano_usb_width = 9;     // USB-C 포트 너비
nano_usb_height = 3.5;  // USB-C 포트 높이

// GC9A01 LCD
lcd_diameter = 35;          // LCD 모듈 전체 직경
lcd_visible = 32;           // 화면 보이는 부분
lcd_depth = 4;              // LCD 두께
lcd_fpc_width = 12;         // FPC 케이블 너비

// INMP441 마이크
mic_length = 14;
mic_width = 10;
mic_height = 3;
mic_hole_diameter = 4;      // 소리 구멍

// MAX98357A 앰프
amp_length = 17;
amp_width = 17;
amp_height = 3;

// 스피커 (소형 20mm)
speaker_diameter = 20;
speaker_depth = 4;

// =====================================
// 📐 케이스 치수
// =====================================

// 케이스 외형 (콤팩트 원형)
case_diameter = 48;         // 케이스 외경 (작아짐!)
case_height = 22;           // 케이스 높이
wall_thickness = 2;         // 벽 두께
back_thickness = 1.5;       // 뒷면 두께

// 베젤
bezel_height = 2;           // LCD 베젤 높이
bezel_inner = lcd_visible - 1;  // 화면 보이는 구멍

// =====================================
// 🎨 색상 (미리보기용)
// =====================================
$fn = 60;  // 원 해상도

// =====================================
// 📦 메인 케이스 본체
// =====================================
module case_body() {
    difference() {
        union() {
            // 메인 원통
            cylinder(h = case_height, d = case_diameter);
            
            // USB 포트 돌출부
            translate([case_diameter/2 - 2, 0, 4])
                usb_port_bump();
        }
        
        // 내부 공간
        translate([0, 0, back_thickness])
            cylinder(h = case_height, d = case_diameter - wall_thickness*2);
        
        // LCD 구멍 (상단)
        translate([0, 0, case_height - lcd_depth])
            cylinder(h = lcd_depth + 1, d = lcd_diameter + 0.5);
        
        // LCD 베젤 단차
        translate([0, 0, case_height - lcd_depth - bezel_height])
            cylinder(h = bezel_height + 0.1, d = lcd_diameter + 3);
        
        // 화면 보이는 구멍
        translate([0, 0, case_height - lcd_depth - bezel_height - 1])
            cylinder(h = lcd_depth + bezel_height + 2, d = bezel_inner);
        
        // 마이크 구멍 (측면 상단)
        translate([case_diameter/2 - wall_thickness, 0, case_height - 6])
            rotate([0, 90, 0])
            cylinder(h = wall_thickness + 2, d = mic_hole_diameter);
        
        // 마이크 구멍 주변 슬롯 (음질 향상)
        for(angle = [-20, 0, 20]) {
            rotate([0, 0, angle])
                translate([case_diameter/2 - wall_thickness, 0, case_height - 6])
                rotate([0, 90, 0])
                cylinder(h = wall_thickness + 2, d = 1.5);
        }
        
        // USB-C 포트 구멍
        translate([case_diameter/2 - wall_thickness - 1, 0, 4])
            rotate([0, 90, 0])
            usb_port_hole();
        
        // 버튼 구멍 (측면, USB 반대편)
        translate([-case_diameter/2 + wall_thickness - 1, 0, case_height/2])
            rotate([0, 90, 0])
            cylinder(h = wall_thickness + 2, d = 6);
        
        // 스피커 구멍 (측면 하단)
        translate([0, 0, 5])
            speaker_holes_side();
        
        // FPC 케이블 슬롯 (LCD용)
        translate([0, -case_diameter/2 + wall_thickness + 5, case_height - lcd_depth - bezel_height - 2])
            cube([lcd_fpc_width, 8, 10], center = true);
    }
    
    // LCD 고정 탭
    lcd_retention_tabs();
}

// USB 포트 돌출부
module usb_port_bump() {
    hull() {
        cube([4, nano_usb_width + 2, nano_usb_height + 4], center = true);
        translate([-2, 0, 0])
            cube([0.1, nano_usb_width, nano_usb_height + 2], center = true);
    }
}

// USB 포트 구멍
module usb_port_hole() {
    hull() {
        translate([0, 0, 0])
            cylinder(h = 10, d = nano_usb_height, center = true);
        translate([0, nano_usb_width/2 - nano_usb_height/2, 0])
            cylinder(h = 10, d = nano_usb_height, center = true);
        translate([0, -nano_usb_width/2 + nano_usb_height/2, 0])
            cylinder(h = 10, d = nano_usb_height, center = true);
    }
}

// 측면 스피커 구멍
module speaker_holes_side() {
    hole_count = 6;
    for(i = [0:hole_count-1]) {
        angle = i * (120 / hole_count) - 60;
        rotate([0, 0, angle])
            translate([case_diameter/2 - wall_thickness, 0, 0])
            rotate([0, 90, 0])
            cylinder(h = wall_thickness + 2, d = 2);
    }
}

// LCD 고정 탭
module lcd_retention_tabs() {
    tab_count = 4;
    for(i = [0:tab_count-1]) {
        rotate([0, 0, i * 90 + 45])
            translate([lcd_diameter/2 + 0.5, 0, case_height - lcd_depth - bezel_height])
            difference() {
                cube([2, 4, bezel_height], center = true);
                translate([1.5, 0, 0])
                    rotate([0, -20, 0])
                    cube([3, 5, bezel_height + 1], center = true);
            }
    }
}

// =====================================
// 📦 케이스 뒷면 (분리형)
// =====================================
module case_back() {
    difference() {
        union() {
            // 메인 원판
            cylinder(h = back_thickness, d = case_diameter);
            
            // 끼워맞춤 돌출부
            translate([0, 0, back_thickness])
                cylinder(h = 2, d = case_diameter - wall_thickness*2 - 0.6);
        }
        
        // 스피커 그릴
        translate([0, 0, -0.5])
            speaker_grill();
        
        // 통풍구
        for(angle = [30, 150, 210, 330]) {
            rotate([0, 0, angle])
                translate([case_diameter/2 - 8, 0, -0.5])
                cylinder(h = back_thickness + 3, d = 2.5);
        }
        
        // 조립 나사 구멍 (선택)
        for(angle = [0, 90, 180, 270]) {
            rotate([0, 0, angle])
                translate([case_diameter/2 - 5, 0, -0.5])
                cylinder(h = back_thickness + 3, d = 2);
        }
    }
}

// 스피커 그릴 패턴
module speaker_grill() {
    // 중앙 원형 패턴
    for(r = [3, 6, 9]) {
        difference() {
            cylinder(h = back_thickness + 1, d = r*2 + 1.2);
            cylinder(h = back_thickness + 2, d = r*2 - 1.2);
        }
    }
    
    // 중앙 구멍
    cylinder(h = back_thickness + 1, d = 2.5);
}

// =====================================
// 📦 내부 트레이 (PCB 고정)
// =====================================
module internal_tray() {
    tray_diameter = case_diameter - wall_thickness*2 - 1;
    tray_height = 12;
    
    difference() {
        union() {
            // 메인 플레이트
            cylinder(h = 1.5, d = tray_diameter);
            
            // ESP32 Nano 홀더
            translate([0, 0, 1.5])
                nano_holder();
            
            // 마이크 홀더
            translate([tray_diameter/2 - mic_length/2 - 3, 0, 1.5])
                mic_holder();
            
            // 앰프 홀더
            translate([-tray_diameter/2 + amp_length/2 + 3, 0, 1.5])
                amp_holder();
        }
        
        // 스피커 공간
        translate([0, 0, -0.5])
            cylinder(h = 2.5, d = speaker_diameter + 2);
        
        // 케이블 통과 구멍들
        translate([0, tray_diameter/2 - 5, -0.5])
            cylinder(h = 3, d = 8);
        
        // 경량화 구멍
        for(angle = [45, 135, 225, 315]) {
            rotate([0, 0, angle])
                translate([tray_diameter/2 - 7, 0, -0.5])
                cylinder(h = 3, d = 5);
        }
    }
}

// ESP32 Nano 홀더
module nano_holder() {
    // 세로 방향으로 배치 (USB가 측면으로 향하게)
    rotate([0, 0, 90]) {
        difference() {
            union() {
                // 지지대
                for(x = [-nano_length/2 + 3, nano_length/2 - 3]) {
                    for(y = [-nano_width/2 + 2, nano_width/2 - 2]) {
                        translate([x, y, 0])
                            cylinder(h = 3, d = 4);
                    }
                }
                
                // 가이드 벽
                translate([0, -nano_width/2 - 0.5, 1.5])
                    cube([nano_length - 10, 1, 3], center = true);
                translate([0, nano_width/2 + 0.5, 1.5])
                    cube([nano_length - 10, 1, 3], center = true);
            }
            
            // 나사 구멍
            for(x = [-nano_length/2 + 3, nano_length/2 - 3]) {
                for(y = [-nano_width/2 + 2, nano_width/2 - 2]) {
                    translate([x, y, -0.5])
                        cylinder(h = 5, d = 1.8);
                }
            }
        }
    }
}

// 마이크 홀더
module mic_holder() {
    difference() {
        union() {
            cube([mic_length + 2, mic_width + 2, 3], center = true);
            translate([0, 0, 1.5])
                difference() {
                    cube([mic_length + 2, mic_width + 2, 3], center = true);
                    cube([mic_length + 0.5, mic_width + 0.5, 4], center = true);
                }
        }
        
        // 마이크 구멍
        translate([0, 0, -2])
            cylinder(h = 8, d = mic_hole_diameter);
    }
}

// 앰프 홀더
module amp_holder() {
    difference() {
        cube([amp_length + 2, amp_width + 2, 3], center = true);
        
        // 앰프 공간
        translate([0, 0, 1])
            cube([amp_length + 0.5, amp_width + 0.5, 3], center = true);
        
        // 통풍 슬롯
        for(y = [-5, 0, 5]) {
            translate([0, y, -2])
                cube([amp_length - 4, 1.5, 6], center = true);
        }
    }
}

// =====================================
// 📦 스피커 홀더 링
// =====================================
module speaker_holder() {
    difference() {
        cylinder(h = 3, d = speaker_diameter + 4);
        
        translate([0, 0, 1])
            cylinder(h = 3, d = speaker_diameter + 0.5);
        
        translate([0, 0, -0.5])
            cylinder(h = 4, d = speaker_diameter - 4);
    }
}

// =====================================
// 📦 시계줄 러그 (선택)
// =====================================
module watch_lugs() {
    lug_width = 18;     // 18mm 밴드용
    lug_length = 12;
    lug_height = 6;
    
    for(side = [1, -1]) {
        translate([side * (case_diameter/2 + 2), 0, case_height/2])
            rotate([0, side * 90 - 90, 0])
            difference() {
                // 러그 본체
                hull() {
                    cube([lug_height, lug_width, wall_thickness], center = true);
                    translate([lug_length - 3, 0, 0])
                        cylinder(h = wall_thickness, d = 5, center = true);
                }
                
                // 스프링바 구멍
                translate([lug_length - 3, lug_width/2 - 1, 0])
                    cylinder(h = wall_thickness + 1, d = 1.5, center = true);
                translate([lug_length - 3, -lug_width/2 + 1, 0])
                    cylinder(h = wall_thickness + 1, d = 1.5, center = true);
            }
    }
}

// =====================================
// 📦 탁상 스탠드
// =====================================
module desk_stand() {
    stand_width = 55;
    stand_depth = 40;
    stand_height = 12;
    stand_angle = 65;
    
    difference() {
        union() {
            // 베이스
            hull() {
                translate([0, stand_depth/2 - 8, 0])
                    cylinder(h = stand_height, d = 25);
                translate([-stand_width/2 + 8, -stand_depth/2 + 8, 0])
                    cylinder(h = 4, d = 16);
                translate([stand_width/2 - 8, -stand_depth/2 + 8, 0])
                    cylinder(h = 4, d = 16);
            }
            
            // 시계 홀더
            translate([0, 0, stand_height])
                rotate([-stand_angle + 90, 0, 0])
                translate([0, 0, 0])
                watch_cradle();
        }
        
        // 케이블 구멍
        translate([0, -stand_depth/2 + 10, -1])
            cylinder(h = stand_height + 5, d = 10);
        
        // 케이블 슬롯
        translate([0, -stand_depth/2, stand_height/2])
            rotate([90, 0, 0])
            cylinder(h = 10, d = 8);
    }
}

// 시계 거치대
module watch_cradle() {
    cradle_depth = 8;
    
    difference() {
        cylinder(h = cradle_depth, d = case_diameter + 4);
        
        translate([0, 0, 2])
            cylinder(h = cradle_depth, d = case_diameter + 0.5);
        
        translate([0, 0, -1])
            cylinder(h = cradle_depth + 2, d = case_diameter - 8);
        
        // 케이블 슬롯
        translate([0, 0, cradle_depth/2])
            rotate([90, 0, 0])
            cylinder(h = case_diameter + 10, d = 10, center = true);
    }
}

// =====================================
// 🖨️ 조립 미리보기
// =====================================
module assembly_preview() {
    color("DimGray") case_body();
    
    translate([0, 0, -back_thickness - 2])
        color("DimGray") case_back();
    
    translate([0, 0, back_thickness + 1])
        color("Gray") internal_tray();
    
    translate([0, 0, back_thickness + 0.5])
        color("DarkGray") speaker_holder();
}

// =====================================
// 🖨️ 렌더링 선택
// =====================================
/*
 * 아래에서 원하는 것을 주석 해제하세요:
 * 
 * 미리보기:
 *   assembly_preview()  - 전체 조립 미리보기
 * 
 * 인쇄용 (STL 내보내기):
 *   case_body()         - 케이스 본체
 *   case_back()         - 케이스 뒷면  
 *   internal_tray()     - 내부 PCB 트레이
 *   speaker_holder()    - 스피커 홀더
 *   desk_stand()        - 탁상 스탠드
 *   watch_lugs()        - 시계줄 러그
 */

// 기본: 조립 미리보기
assembly_preview();

// === 인쇄용 (하나씩 주석 해제) ===
// case_body();
// case_back();
// internal_tray();
// speaker_holder();
// desk_stand();
// watch_lugs();
