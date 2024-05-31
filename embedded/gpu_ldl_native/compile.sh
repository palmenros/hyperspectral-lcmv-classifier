make -f native_multi_target_detection_ldl_rtw.mk
nvcc *.cu *.cpp -L./native_multi_target_detection_ldl_fp32_cuda.a -lcublas -lcusolver
