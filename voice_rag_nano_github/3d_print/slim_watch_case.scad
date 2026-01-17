/*
 * ⌚ ESP32-S3 Nano 슬림 시계 케이스
 * 
 * 더 얇고 손목에 착용하기 좋은 디자인
 * LCD와 필수 부품만 포함 (앰프/스피커 외장)
 * 
 * 이 버전의 특징:
 * - 두께 15mm 이하
 * - 마이크만 내장
 * - 스피커/앰프는 별도 연결 또는 블루투스
 */

// =====================================
// 📐 치수 설정
// =====================================

// 케이스
case_diameter = 44;     // 더 작은 직경
case_height = 15;       // 슬림한 높이
wall = 2;               // 벽 두께
back_wall = 1.5;

// LCD
lcd_outer = 35;
lcd_visible = 32;
lcd_depth = 4;

// ESP32-S3 Nano (측면 배치)
nano_l = 48;
nano_w = 25.4;
nano_h = 5;

// 마이크
mic_hole = 3;

$fn = 60;

// =====================================
// 슬림 케이스 본체
// =====================================
module slim_case_body() {
    difference() {
        // 외형 - 약간 타원형
        scale([1, 1.15, 1])
            cylinder(h = case_height, d = case_diameter);
        
        // 내부 공간
        translate([0, 0, back_wall])
            scale([1, 1.15, 1])
            cylinder(h = case_height, d = case_diameter - wall*2);
        
        // LCD 구멍
        translate([0, 0, case_height - lcd_depth])
            cylinder(h = lcd_depth + 1, d = lcd_outer + 0.5);
        
        // LCD 화면 구멍
        translate([0, 0, case_height - lcd_depth - 2])
            cylinder(h = lcd_depth + 3, d = lcd_visible);
        
        // 마이크 구멍 (상단 측면)
        translate([case_diameter/2 - wall, 0, case_height - 4])
            rotate([0, 90, 0])
            cylinder(h = wall + 2, d = mic_hole);
        
        // USB 포트 (하단)
        translate([0, -case_diameter * 1.15/2 + wall, 4])
            rotate([90, 0, 0])
            hull() {
                cylinder(h = wall + 2, d = 3.5);
                translate([4, 0, 0]) cylinder(h = wall + 2, d = 3.5);
                translate([-4, 0, 0]) cylinder(h = wall + 2, d = 3.5);
            }
        
        // 버튼 구멍 (우측)
        translate([case_diameter/2 - wall, 5, case_height/2])
            rotate([0, 90, 0])
            cylinder(h = wall + 2, d = 5);
    }
}

// =====================================
// 슬림 케이스 뒷면
// =====================================
module slim_case_back() {
    difference() {
        scale([1, 1.15, 1])
            cylinder(h = back_wall, d = case_diameter);
        
        // 통풍구 패턴
        for(angle = [0:45:315]) {
            rotate([0, 0, angle])
                translate([case_diameter/2 - 8, 0, -0.5])
                cylinder(h = back_wall + 1, d = 2);
        }
        
        // 중앙 통풍
        for(r = [4, 8]) {
            difference() {
                cylinder(h = back_wall + 1, d = r*2 + 1);
                translate([0, 0, -0.5])
                    cylinder(h = back_wall + 2, d = r*2 - 1);
            }
        }
    }
    
    // 끼워맞춤 테두리
    translate([0, 0, back_wall])
        difference() {
            scale([1, 1.15, 1])
                cylinder(h = 1.5, d = case_diameter - wall*2 - 0.5);
            scale([1, 1.15, 1])
                cylinder(h = 2, d = case_diameter - wall*2 - 2);
        }
}

// =====================================
// 슬림 시계줄 러그
// =====================================
module slim_lugs() {
    lug_width = 18;  // 18mm 밴드
    
    for(side = [1, -1]) {
        translate([0, side * (case_diameter * 1.15/2 + 2), case_height/2])
            rotate([side * 90 - 90, 0, 0])
            difference() {
                hull() {
                    cube([lug_width, 4, wall], center = true);
                    translate([0, 8, 0])
                        cylinder(h = wall, d = 6, center = true);
                }
                
                // 스프링바 구멍
                translate([lug_width/2 - 2, 8, 0])
                    cylinder(h = wall + 1, d = 1.5, center = true);
                translate([-lug_width/2 + 2, 8, 0])
                    cylinder(h = wall + 1, d = 1.5, center = true);
            }
    }
}

// =====================================
// 슬림 내부 프레임
// =====================================
module slim_internal_frame() {
    frame_d = case_diameter - wall*2 - 1;
    
    difference() {
        scale([1, 1.15, 1])
            cylinder(h = 1.5, d = frame_d);
        
        // ESP32 공간
        translate([0, 0, -0.5])
            cube([nano_w + 1, nano_l - 5, 3], center = true);
        
        // 케이블 구멍
        translate([0, frame_d/2 - 5, -0.5])
            cylinder(h = 3, d = 6);
    }
    
    // ESP32 지지대
    for(x = [-nano_w/2 + 2, nano_w/2 - 2]) {
        for(y = [-15, 15]) {
            translate([x, y, 1.5])
                difference() {
                    cylinder(h = 2, d = 4);
                    cylinder(h = 3, d = 1.5);
                }
        }
    }
}

// =====================================
// 미리보기
// =====================================
module slim_assembly() {
    color("DimGray") slim_case_body();
    color("DimGray") slim_lugs();
    
    translate([0, 0, -3])
        color("Gray") slim_case_back();
    
    translate([0, 0, back_wall + 0.5])
        color("Silver") slim_internal_frame();
}

// =====================================
// 렌더링
// =====================================

// 미리보기
slim_assembly();

// 인쇄용
// slim_case_body();
// slim_case_back();
// slim_internal_frame();
// slim_lugs();
