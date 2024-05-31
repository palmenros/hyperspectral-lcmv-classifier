make -f native_multi_target_detection_ldl_rtw.mk
nvcc *.c -L./native_multi_target_detection_ldl_fp32_cuda.a
