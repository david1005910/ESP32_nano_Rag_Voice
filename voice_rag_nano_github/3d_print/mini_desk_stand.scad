/*
 * 🖥️ ESP32-S3 Nano 미니 탁상 스탠드
 * 
 * 컴팩트한 Nano 보드용 책상 위 스탠드
 * 모든 부품 내장 가능
 */

// =====================================
// 📐 치수
// =====================================

// 케이스 (세로형)
case_width = 50;        // 가로
case_depth = 35;        // 세로 (깊이)
case_height = 70;       // 높이
wall = 2.5;
corner_radius = 8;

// LCD 위치
lcd_diameter = 35;
lcd_center_y = case_height - 25;

// 스피커
speaker_d = 20;

// ESP32-S3 Nano
nano_l = 48;
nano_w = 25.4;

// 디스플레이 각도
lcd_angle = 10;  // 살짝 뒤로 기울임

$fn = 40;

// =====================================
// 둥근 박스 모듈
// =====================================
module rounded_box(w, d, h, r) {
    hull() {
        for(x = [-w/2 + r, w/2 - r]) {
            for(y = [-d/2 + r, d/2 - r]) {
                translate([x, y, 0])
                    cylinder(h = h, r = r);
            }
        }
    }
}

// =====================================
// 메인 스탠드 케이스
// =====================================
module stand_case() {
    difference() {
        // 외형 (뒤로 기울어진)
        rotate([lcd_angle, 0, 0])
            rounded_box(case_width, case_depth, case_height, corner_radius);
        
        // 내부 공간
        rotate([lcd_angle, 0, 0])
            translate([0, 0, wall])
            rounded_box(case_width - wall*2, case_depth - wall*2, case_height, corner_radius - wall);
        
        // LCD 구멍
        rotate([lcd_angle, 0, 0])
            translate([0, -case_depth/2 + 5, lcd_center_y])
            rotate([90, 0, 0])
            cylinder(h = 10, d = lcd_diameter + 1);
        
        // LCD 화면 구멍
        rotate([lcd_angle, 0, 0])
            translate([0, -case_depth/2, lcd_center_y])
            rotate([90, 0, 0])
            cylinder(h = 15, d = lcd_diameter - 3);
        
        // 마이크 구멍 (상단)
        rotate([lcd_angle, 0, 0])
            translate([0, -case_depth/2, case_height - 8])
            rotate([90, 0, 0])
            cylinder(h = wall + 2, d = 4);
        
        // 스피커 구멍 (전면 하단)
        rotate([lcd_angle, 0, 0])
            translate([0, -case_depth/2, 15])
            rotate([90, 0, 0])
            speaker_grill_small();
        
        // USB 포트 (후면 하단)
        translate([0, case_depth/2 - wall, 8])
            rotate([90, 0, 0])
            hull() {
                cylinder(h = wall + 2, d = 4);
                translate([5, 0, 0]) cylinder(h = wall + 2, d = 4);
                translate([-5, 0, 0]) cylinder(h = wall + 2, d = 4);
            }
        
        // 버튼 구멍 (측면)
        translate([case_width/2 - wall, 0, lcd_center_y])
            rotate([0, 90, 0])
            cylinder(h = wall + 2, d = 6);
        
        // 바닥 (수평 유지)
        translate([0, 0, -20])
            cube([case_width + 10, case_depth + 10, 20], center = true);
    }
    
    // 바닥 플레이트 (수평)
    bottom_plate();
}

// 바닥 플레이트
module bottom_plate() {
    plate_w = case_width + 10;
    plate_d = case_depth + 15;
    plate_h = 3;
    
    difference() {
        // 플레이트
        translate([0, 5, 0])
            rounded_box(plate_w, plate_d, plate_h, 5);
        
        // 고무 패드 위치
        for(x = [-plate_w/2 + 8, plate_w/2 - 8]) {
            for(y = [-plate_d/2 + 13, plate_d/2 - 3]) {
                translate([x, y, -0.5])
                    cylinder(h = 2, d = 8);
            }
        }
        
        // 케이블 구멍
        translate([0, plate_d/2 - 5, -0.5])
            hull() {
                cylinder(h = plate_h + 1, d = 6);
                translate([0, 10, 0]) cylinder(h = plate_h + 1, d = 6);
            }
    }
}

// 작은 스피커 그릴
module speaker_grill_small() {
    // 동심원
    for(r = [3, 6, 9]) {
        difference() {
            cylinder(h = wall + 1, d = r*2 + 1);
            cylinder(h = wall + 2, d = r*2 - 1);
        }
    }
    cylinder(h = wall + 1, d = 2);
}

// =====================================
// 내부 트레이
// =====================================
module stand_internal_tray() {
    tray_w = case_width - wall*2 - 2;
    tray_d = case_depth - wall*2 - 2;
    
    difference() {
        // 베이스
        rounded_box(tray_w, tray_d, 2, corner_radius - wall - 1);
        
        // 스피커 공간
        translate([0, 0, -0.5])
            cylinder(h = 3, d = speaker_d + 2);
    }
    
    // ESP32 마운트
    translate([0, 0, 2])
        rotate([0, 0, 90])  // 세로 배치
        esp32_mount();
    
    // 스피커 홀더
    difference() {
        cylinder(h = 4, d = speaker_d + 4);
        translate([0, 0, 1.5])
            cylinder(h = 4, d = speaker_d + 0.5);
        translate([0, 0, -0.5])
            cylinder(h = 5, d = speaker_d - 4);
    }
}

// ESP32 마운트
module esp32_mount() {
    // 지지대
    for(x = [-nano_l/2 + 4, nano_l/2 - 4]) {
        for(y = [-nano_w/2 + 3, nano_w/2 - 3]) {
            translate([x, y, 0])
                difference() {
                    cylinder(h = 3, d = 4);
                    cylinder(h = 4, d = 1.8);
                }
        }
    }
}

// =====================================
// LCD 마운트 링
// =====================================
module lcd_mount_ring() {
    difference() {
        cylinder(h = 3, d = lcd_diameter + 4);
        
        translate([0, 0, 1])
            cylinder(h = 3, d = lcd_diameter + 0.5);
        
        translate([0, 0, -0.5])
            cylinder(h = 4, d = lcd_diameter - 3);
    }
    
    // 고정 탭
    for(angle = [0, 90, 180, 270]) {
        rotate([0, 0, angle])
            translate([lcd_diameter/2 + 1, 0, 2.5])
            sphere(d = 2, $fn = 15);
    }
}

// =====================================
// 미리보기
// =====================================
module stand_assembly() {
    color("DimGray") stand_case();
    
    rotate([lcd_angle, 0, 0])
        translate([0, 0, wall + 1])
        color("Silver") stand_internal_tray();
}

// =====================================
// 렌더링
// =====================================

// 미리보기
stand_assembly();

// 인쇄용
// stand_case();
// stand_internal_tray();
// lcd_mount_ring();
