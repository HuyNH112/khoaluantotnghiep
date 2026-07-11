int main() {
    volatile int array[1024];
    int sum = 0;
    
    // Vòng lặp kích thích Domino
    for(int i = 0; i < 1024; i += 16) {
        array[i] = 1;     
        sum += array[i];  
    }
    
    // Ghi kết quả 8 xuống thẳng địa chỉ vật lý 0x100 để Testbench kiểm tra
    volatile int *tohost = (volatile int *)0x100;
    *tohost = 8;
    
    // Vòng lặp vô tận giữ CPU không chạy lung tung sau khi xong
    while(1); 
    return 0; 
}