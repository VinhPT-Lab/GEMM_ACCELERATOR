<img width="1638" height="1145" alt="image" src="https://github.com/user-attachments/assets/ec141830-06c6-4635-872b-acf995dab94d" />
<img width="1864" height="939" alt="image" src="https://github.com/user-attachments/assets/b2010241-eaa6-4294-9237-b99101a3f08c" />
<img width="1843" height="1118" alt="image" src="https://github.com/user-attachments/assets/e585e315-826e-4493-8472-8f4b1aacfb4b" />
GEMM_TOP

Tín hiệu
I/O
Mô tả
clk
I
Tín hiệu clock dùng cho toàn bộ module GEMM_TOP và lõi MM_ultra
rst_n
I
Tín hiệu reset active-low dùng để khởi tạo lại hệ thống
shift[9:0]
Reg
Thanh ghi cấu hình từ AXI4-Lite Control, dùng để dịch phải kết quả trước khi xuất ra int8
F_length[8:0]
Reg
Thanh ghi cấu hình số dòng của ma trận feature cần xử lý
F_width[4:0]
Reg
Thanh ghi cấu hình số block theo chiều rộng của feature, tương ứng chiều K của phép GEMM
W_width[4:0]
Reg
Thanh ghi cấu hình số block theo chiều rộng của weight/output, tương ứng chiều N của phép GEMM
feature_data[127:0]
I
Dữ liệu feature truyền từ khối Feature AXI4-Stream Slave vào MM_ultra; mỗi beat gồm 16 phần tử int8
feature_valid
I
Tín hiệu từ khối Feature báo dữ liệu feature hiện tại hợp lệ
feature_ready
O
Tín hiệu từ MM_ultra báo đã sẵn sàng nhận dữ liệu feature
feature_last
I
Tín hiệu báo beat cuối cùng của luồng feature
weight_data[127:0]
I
Dữ liệu weight truyền từ khối Weight AXI4-Stream Slave vào MM_ultra; mỗi beat gồm 16 phần tử int8
weight_valid
I
Tín hiệu từ khối Weight báo dữ liệu weight hiện tại hợp lệ
weight_ready
O
Tín hiệu từ MM_ultra báo đã sẵn sàng nhận dữ liệu weight
weight_last
I
Tín hiệu báo beat cuối cùng của luồng weight
result_data[127:0]
O
Dữ liệu kết quả GEMM từ MM_ultra đưa sang khối Result AXI4-Stream Master; mỗi beat gồm 16 phần tử int8
result_valid
O
Tín hiệu từ MM_ultra báo dữ liệu kết quả hiện tại hợp lệ
result_ready
I
Tín hiệu từ khối Result báo bên nhận đã sẵn sàng nhận dữ liệu
result_last
O
Tín hiệu báo beat cuối cùng của luồng kết quả






Bảng Tham số MM_Top
Tên
Loại
Giá trị/Độ rộng
Mô tả
C_S_AXI_DATA_WIDTH
Parameter
32
Độ rộng dữ liệu của AXI4-Lite control bus.
C_S_AXI_ADDR_WIDTH
Parameter
4
Độ rộng địa chỉ của AXI4-Lite control bus.


MM_ULTRA

Bảng 1: Danh sách Tín hiệu (Signals) 
Tín hiệu
Thuộc input hay output
Tín hiệu đó là gì
clk
Input
Clock chính của toàn bộ module. Tất cả buffer, counter, FSM chạy theo clock này.
rst_n
Input
Reset active-low. Khi rst_n = 0 thì reset hệ thống.
shift_in
Input
Giá trị dịch phải dùng cho right_shifter trong MM_out_buffer, dùng để scale kết quả trước khi xuất INT8.
F_length_in
Input
Số hàng của ma trận feature F, có thể hiểu là số vector/token đầu vào cần xử lý.
F_width_block_num_in
Input
Số block theo chiều rộng của feature F. Nếu feature rộng hơn A_size thì phải chia thành nhiều block.
W_width_block_num_in
Input
Số block theo chiều rộng của weight/output. Quy định output có bao nhiêu block cột.
in_F_valid
Input
Báo dữ liệu feature đầu vào in_F_data đang hợp lệ.
in_F_last
Input
Báo beat cuối của luồng feature input.
in_F_data
Input
Dữ liệu feature đầu vào. Mỗi lần truyền vào một vector có A_size phần tử, mỗi phần tử data_width bit.
in_F_ready
Output
Báo GEMM_ultra sẵn sàng nhận feature mới.
in_W_valid
Input
Báo dữ liệu weight đầu vào in_W_data đang hợp lệ.
in_W_last
Input
Báo beat cuối của luồng weight input.
in_W_data
Input
Dữ liệu weight đầu vào. Mỗi lần truyền vào một vector có A_size phần tử, mỗi phần tử data_width bit.
in_W_ready
Output
Báo GEMM_ultra sẵn sàng nhận weight mới.
out_data_valid
Output
Báo dữ liệu output out_data hiện tại hợp lệ.
out_data_ready
Input
Bên nhận output báo rằng nó sẵn sàng nhận dữ liệu.
out_data_last
Output
Báo beat cuối của toàn bộ output.
out_data
Output
Dữ liệu kết quả cuối cùng sau khi tính GEMM, cộng dồn partial sum, shift và saturate về data_width bit.


Bảng 2: Danh sách Tham số (Parameters) 

PARAMETER
Giá trị mặc định
Chức năng
A_size
16
Kích thước tile/systolic array. Một lần xử lý A_size phần tử. Nếu A_size = 16, mỗi vector input có 16 số INT8, PE array xử lý tile 16 x 16.
data_width
8
Độ rộng bit của mỗi phần tử input/weight/output. Với data_width = 8 tức là dữ liệu dạng INT8.
shift_width
10
Độ rộng bit của tín hiệu shift_in. Tín hiệu này dùng trong right_shifter để dịch phải kết quả trước khi xuất output.
Weight_Block_num
2400
Số lượng phần tử/block tối đa mà buffer weight có thể lưu. Đây là dung lượng tối đa, không phải số block thực tế đang chạy.
IN_Feature_Block_num
2400
Số lượng phần tử/block tối đa mà input feature buffer có thể lưu. Đây là dung lượng tối đa của MM_in_buffer cho feature.
OUT_Feature_Block_num
2400
Số lượng phần tử/block tối đa mà output buffer có thể lưu. Dùng trong MM_out_buffer để lưu kết quả cộng dồn.
OUT_MEM_WIDTH
32
Độ rộng bit của bộ nhớ output trung gian trong MM_out_buffer. Vì kết quả MAC/cộng dồn có thể lớn hơn INT8 nên thường dùng 32-bit để lưu partial sum.
F_length_width
9
Số bit dùng để biểu diễn F_length. Nếu F_length_width = 9, thì F_length có thể biểu diễn tối đa khoảng 2^9 = 512 giá trị.
F_width_block_num_width
5
Số bit dùng để biểu diễn F_width_block_num. Đây là số block theo chiều rộng của feature/input matrix.
W_width_block_num_width
5
Số bit dùng để biểu diễn W_width_block_num. Đây là số block theo chiều rộng của weight/output matrix.


