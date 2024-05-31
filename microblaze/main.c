#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"

#include "xgpio.h"
#include "xaxidma.h"
#include "xintc.h"
#include "sleep.h"

XGpio Gpio;
XGpio VersionConstantGpio;

XAxiDma AxiDma0;
XAxiDma AxiDma1;

#define LED_CHANNEL 1
#define LED 0xff

#define LED_DELAY     10000000

uint8_t rotate_left(uint8_t n, uint8_t num_bits) {
	return (n << num_bits) | (n >> (8 - num_bits));
}

#define KB 1024
#define MB 1024 * KB

static unsigned int g_seed;

void fast_srand(int seed) {
    g_seed = seed;
}

// Output value in range [0, 32767]
int fast_rand(void) {
    g_seed = (214013*g_seed+2531011);
    return (g_seed>>16)&0x7FFF;
}

volatile uint8_t* ram = (uint8_t*)XPAR_MIG7SERIES_0_BASEADDR;

int ram_check_test() {

	const long srand_seed = 324345;
	fast_srand(srand_seed);

	// RAM SELF TEST
	for (size_t i = 0; i < 2 * MB; i++) {
		uint8_t value = fast_rand() & 0xff;

		ram[i] = value;

		if((i & 0x3ffff) == 0) {
			xil_printf("Wrote to address %p value %d\n", (ram+i), value);
		}
	}

	fast_srand(srand_seed);

	for (size_t i = 0; i < 2 * MB; i++) {
		uint8_t value = fast_rand() & 0xff;

		uint8_t ram_value = ram[i];

		if((i & 0x3ffff) == 0) {
			xil_printf("Read from address %p value %d\n", (ram+i), ram_value );
		}

		if (ram_value != value) {
			xil_printf("Value mismatch! Should be %d and is %d\n", value, ram_value);
			return XST_FAILURE;
		}

	}

	print("\n\nRam check passed!\n\r");
	return XST_SUCCESS;
}

int initialize_dma(XAxiDma* dma, u16 deviceId) {

	XAxiDma_Config* cfg = XAxiDma_LookupConfig(deviceId);
	if (!cfg) {
		xil_printf("No config found for %d\n", deviceId);
		return XST_FAILURE;
	}

	int status = XAxiDma_CfgInitialize(dma, cfg);
	if (status != XST_SUCCESS) {
		xil_printf("Initialization for DMA %d failed %d\n", deviceId, status);
		return XST_FAILURE;
	}

	if(XAxiDma_HasSg(dma)){
		xil_printf("Device %d configured as SG mode\n", deviceId);
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

void dma_disable_all_interrupts(XAxiDma* dma) {
	XAxiDma_IntrDisable(dma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrDisable(dma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
}

int print_version() {
	int Status = XGpio_Initialize(&VersionConstantGpio, XPAR_GPIO_1_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("Version Gpio Initialization Failed\n");
		return XST_FAILURE;
	}

	const int version_channel = 1;

	XGpio_SetDataDirection(&VersionConstantGpio, version_channel, ~0);
	u32 version = XGpio_DiscreteRead(&VersionConstantGpio, version_channel);
	xil_printf("\nHardware version: %d \n\n", version);

	return XST_SUCCESS;
}

const uint32_t tc_init[] = {0x463df000, 0x46734400, 0x46516800, 0x4776ef00, 0x477ea900, 0x461b2400, 0x46de5c00, 0x4580c000, 0x464da000, 0x46db7800, 0x47682500, 0x44cd6000, 0x471f5500, 0x47192300, 0x4688e200, 0x477e2500, 0x46898e00, 0x47302300, 0x45ab7000, 0x46f22800, 0x46c7ba00, 0x477aec00, 0x4697f600, 0x470b5f00, 0x4624b800, 0x4753aa00, 0x46a01a00, 0x47125200, 0x47589e00, 0x4622b800, 0x47743e00, 0x47125f00, 0x46a1e800, 0x4526c000, 0x46896600, 0x4764d300, 0x471c9600, 0x474f3c00, 0x46a8a200, 0x4741d300, 0x47574d00, 0x4766cc00, 0x46bb2400, 0x47359800, 0x471bf300, 0x472eec00, 0x46cac600, 0x4732e400, 0x475c3e00, 0x47778900, 0x462fec00, 0x47315a00, 0x47222900, 0x47003b00, 0x4745f900, 0x3f12a741, 0x3ddab27d, 0x3f36b3cb, 0x3ee683b2, 0x3f3c21fd, 0x3eb891a6, 0x3e92f925, 0x3eb58d16, 0x3f37ecf7, 0x3f409c68, 0x3f14a467, 0x3f7ecd89, 0x3dc13eda, 0x3e990394, 0x3dab6af6};

int test_dma() {

	// Seed using to generate random data
	const long srand_seed = 7;

	print("Starting DMA test...\n");

	// Initialize DMA 0
	int status = initialize_dma(&AxiDma0, XPAR_AXI_DMA_0_DEVICE_ID);
	if(status != XST_SUCCESS) {
		print("Failed to initialize DMA 0 \n");
		return XST_FAILURE;
	}

	status = initialize_dma(&AxiDma1, XPAR_AXI_DMA_1_DEVICE_ID);
	if(status != XST_SUCCESS) {
		print("Failed to initialize DMA 1 \n");
		return XST_FAILURE;
	}

	dma_disable_all_interrupts(&AxiDma0);
	dma_disable_all_interrupts(&AxiDma1);

	// Set up transaction to DMA
	const int transaction_length = 0x200;

	fast_srand(srand_seed);

	volatile uint8_t* send_transaction_start = ram;

	// Fill up send_transaction_buffer
	for(int i = 0; i < transaction_length; i++) {
		uint8_t value = fast_rand();
		send_transaction_start[i] = value;

		if((i & 0xcf) == 0)  {
			xil_printf("Wrote to AxiDma0 send buff at pos %p value %d \n", send_transaction_start+i, value);
		}
	}

	volatile uint8_t* recv_transaction_start = ram + 0x10000;

	// Flush caches
	Xil_DCacheFlushRange((UINTPTR)send_transaction_start, transaction_length);
	Xil_DCacheFlushRange((UINTPTR)recv_transaction_start, transaction_length);

	// XAXIDMA_DEVICE_TO_DMA: Verilog to Microblaze
	// XAXIDMA_DMA_TO_DEVICE: Microblaze to Verilog
	status = XAxiDma_SimpleTransfer(&AxiDma1, recv_transaction_start, transaction_length, XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) {
		print("XAxiDma1 simple transfer failed \n");
		return XST_FAILURE;
	}

	print("XAxiDma1 simple transfer transfer started\n");

	status = XAxiDma_SimpleTransfer(&AxiDma0, send_transaction_start, transaction_length, XAXIDMA_DMA_TO_DEVICE);

	if (status != XST_SUCCESS) {
		print("XAxiDma0 simple transfer failed \n");
		return XST_FAILURE;
	}

	print("XAxiDma0 simple transfer transfer started\n");
	while (XAxiDma_Busy(&AxiDma0,XAXIDMA_DMA_TO_DEVICE) || XAxiDma_Busy(&AxiDma1,XAXIDMA_DEVICE_TO_DMA)) {
					/* Wait */
	}

	print("DMA transaction finished!\n");

	// Check received values
	Xil_DCacheInvalidateRange(recv_transaction_start, transaction_length);

	fast_srand(srand_seed);
	for(int i = 0; i < transaction_length; i++) {
		uint8_t expected_value = fast_rand();
		uint8_t actual_value = recv_transaction_start[i];

		if((i & 0xcf) == 0) {
			xil_printf("Read from address %p value %d\n", (recv_transaction_start+i), actual_value );
		}

		if (actual_value != expected_value) {
			xil_printf("Value mismatch! Should be %d and is %d\n", expected_value, actual_value);
			return XST_FAILURE;
		}

	}



	print("DMA test passed!\n\n");
	return XST_SUCCESS;
}

static XIntc InterruptController;

volatile int finished_loading = 0;

void finishedLoadingInterruptHandler(void *CallbackRef) {
	finished_loading = 1;
	print("Finished loading interrupt triggered! \n");
}

volatile int accelerator_finished = 0;

void acceleratorFinishedInterruptHandler(void *CallbackRef) {
	accelerator_finished = 1;
	print("Accelerator finished interrupt triggered! \n");
}

int send_dma_tc_data() {
	// Initialize DMA 0
	int status = initialize_dma(&AxiDma0, XPAR_AXI_DMA_0_DEVICE_ID);
	if(status != XST_SUCCESS) {
		print("Failed to initialize DMA 0 \n");
		return XST_FAILURE;
	}

	/////////////////////////////////////////////////////
	// BEGIN SET UP INTERRUPTS
	/////////////////////////////////////////////////////

	status = XIntc_Initialize(&InterruptController, XPAR_INTC_0_DEVICE_ID);
	if (status != XST_SUCCESS) {
		print("Failed to initialize interrupt controller \n");
		return XST_FAILURE;
	}

	// NOTE: DESTRUCTIVE TEST
//	status = XIntc_SelfTest(&InterruptController);
//	if (status != XST_SUCCESS) {
//		print("Interrupt self-test FAILED \n");
//		return XST_FAILURE;
//	}
//	print("Interrupt self-test PASSED \n");

	const int finished_loading_intc_id = XPAR_AXI_INTC_0_WEIGHTING_MATRIX_TC_0_FINISHED_LOADING_INTR;

	status = XIntc_Connect(&InterruptController, finished_loading_intc_id,
					   (XInterruptHandler)finishedLoadingInterruptHandler,
					   (void *)0);
	if (status  != XST_SUCCESS) {
		print("XIntc Connect failed!\n");
		return XST_FAILURE;
	}


	const int accelerator_finished_intc_id = XPAR_AXI_INTC_0_WEIGHTING_MATRIX_TC_0_FINISHED_INTR;
	status = XIntc_Connect(&InterruptController, accelerator_finished_intc_id,
					   (XInterruptHandler)acceleratorFinishedInterruptHandler,
					   (void *)0);
	if (status  != XST_SUCCESS) {
		print("XIntc Connect failed!\n");
		return XST_FAILURE;
	}



	status = XIntc_Start(&InterruptController, XIN_REAL_MODE);
	if (status != XST_SUCCESS) {
		print("XIntc Start failed!\n");
		return XST_FAILURE;
	}

	print("XInt Start succesful\n");

	XIntc_Enable(&InterruptController, finished_loading_intc_id);
	XIntc_Enable(&InterruptController, accelerator_finished_intc_id);

	print("Loop setup finished\n");

	Xil_ExceptionInit();

	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
				(Xil_ExceptionHandler)XIntc_InterruptHandler,
				&InterruptController);

	Xil_ExceptionEnable();

	print("Interrupts enabled\n");

	/////////////////////////////////////////////////////
	// END SET UP INTERRUPTS
	/////////////////////////////////////////////////////

	xil_printf("Sending %d bytes via DMA 0 \n", sizeof(tc_init));
	dma_disable_all_interrupts(&AxiDma0);

	const int transaction_length = sizeof(tc_init);
	volatile uint8_t* send_transaction_start = ram;

	// Copy to RAM
	memcpy(send_transaction_start, tc_init, transaction_length);

	// Read out first element of RAM
	volatile uint32_t* tc_data = ram;

	const int num_first_values = 5;

	xil_printf("Printing %d first values to send via DMA 0 \n", num_first_values);

	for(int i = 0; i < num_first_values; ++i) {
		xil_printf("Value number %d is %p\n", i, tc_data[i]);
	}

	const int num_last_values = 5;
	xil_printf("Printing %d last values to send via DMA 0 \n", num_last_values);

	const int num_total_values = transaction_length / sizeof(uint32_t);

	for(int i = num_total_values - num_first_values; i < num_total_values; i++) {
		xil_printf("Value number %d is %p\n", i, tc_data[i]);
	}

	// Flush caches
	Xil_DCacheFlushRange((UINTPTR)send_transaction_start, transaction_length);

	status = XAxiDma_SimpleTransfer(&AxiDma0, send_transaction_start, transaction_length, XAXIDMA_DMA_TO_DEVICE);

	if (status != XST_SUCCESS) {
		print("XAxiDma0 simple transfer failed \n");
		return XST_FAILURE;
	}

	print("XAxiDma0 simple transfer transfer started\n");

	while (XAxiDma_Busy(&AxiDma0,XAXIDMA_DMA_TO_DEVICE)) {
					/* Wait */
	}

	print("DMA0 transfer finished! \n");

//	status = XIntc_SimulateIntr(&InterruptController, finished_loading_intc_id);
//	if (status != XST_SUCCESS) {
//		print("Couldn't simulate interrupt\n");
//		return XST_FAILURE;
//	}
//	print("Interrupt simulated!\n");

//	usleep(1000000);

	while(!finished_loading) {
		/* Wait */
	}

	print("Finished loading=1! Without simulating! \n");

	return XST_SUCCESS;
}

const int32_t pixels_data[] = {0x46efba00, 0x460a3400, 0x46467000, 0x477d0100, 0x43cd0000, 0x46cce200, 0x4687e200, 0x473a7400, 0x4762bf00, 0x47053900, 0x47426100, 0x45c02000, 0x4584f800, 0x46e56000, 0x46f28c00, 0x462f9000, 0x47191200, 0x474abd00, 0x47511100, 0x46975200, 0x459bd800, 0x46a65600, 0x4739a500, 0x472c2600, 0x471e2900, 0x473f3300, 0x469b6c00, 0x47695a00, 0x476fd700, 0x45ee0800, 0x46973c00, 0x46d00200, 0x47059700, 0x47697c00, 0x46f6e400, 0x47181f00, 0x472b8300, 0x473e9600, 0x46083000, 0x47117a00, 0x46fa2600, 0x47683700, 0x46dc4600, 0x4773af00, 0x45b10000, 0x46fda800, 0x472a7700, 0x474bac00, 0x4714b600, 0x452cc000, 0x47702300, 0x46b1e600, 0x46fc5c00, 0x4728c900, 0x472b4300, 0x47051c00, 0x46a08200, 0x46890e00, 0x468b8c00, 0x47338300, 0x46cd5600, 0x4718e600, 0x47461e00, 0x46542000, 0x465fa400, 0x46f23e00, 0x470d7a00, 0x46a5a200, 0x46d90600, 0x46915e00, 0x474dff00, 0x47188100, 0x477ceb00, 0x46921200, 0x44d3a000, 0x45a61800, 0x47263e00, 0x472f6600, 0x4768bb00, 0x474ca100, 0x47379f00, 0x475a1c00, 0x476b7100, 0x47432a00, 0x47530c00, 0x462e4c00, 0x46ef7400, 0x472a6800, 0x46996e00, 0x46e69400, 0x476ead00, 0x463d1400, 0x45f11800, 0x46966a00, 0x463e1400, 0x46313800, 0x469ace00, 0x473a8b00, 0x466bac00, 0x471a1500, 0x473fa700, 0x46f08000, 0x47556e00, 0x47284300, 0x470b8800, 0x47044c00, 0x475d1800, 0x47762100, 0x471d2f00, 0x474e0e00, 0x464b4800, 0x463db400, 0x469cd400, 0x462dc000, 0x4740c200, 0x47481d00, 0x4723e200, 0x476d1200, 0x47489e00, 0x47668e00, 0x4700b700, 0x47282200, 0x45adf000, 0x46e0f600, 0x47740a00, 0x4733bf00, 0x46a7a200, 0x475e7400, 0x4643b400, 0x472c5b00, 0x46816e00, 0x46de3a00, 0x4732c800, 0x46540000, 0x469d1e00, 0x4738f900, 0x471aea00, 0x45c32000, 0x4719a200, 0x454e4000, 0x47573a00, 0x46616400, 0x47358400, 0x46eb5c00, 0x470f1600, 0x468cd000, 0x46097c00, 0x451cc000, 0x46e22600, 0x477feb00, 0x470c6800, 0x46d77c00, 0x46717800, 0x470e2600, 0x46217400, 0x47296600, 0x460e1400, 0x475a6500, 0x4647d800, 0x44ee4000, 0x46044800, 0x441c0000, 0x47342900, 0x474f6500, 0x46829000, 0x46d7f600, 0x47707100, 0x462a8c00, 0x476e8400, 0x46a95000, 0x472ce700, 0x46963600, 0x47541000, 0x46f66c00, 0x4733d200, 0x459a0800, 0x47189800, 0x4524e000, 0x46fce800, 0x47106f00, 0x47249100, 0x45e49000, 0x46f42a00, 0x47689700, 0x47521200, 0x4760e600, 0x4716d000, 0x46a50a00, 0x46279800, 0x45b15800, 0x46cc3400, 0x465ea000, 0x464c7000, 0x4604b400, 0x47348f00, 0x46dff200, 0x47360500, 0x472c9c00, 0x4754ab00, 0x46e05200, 0x476d4600, 0x46e21a00, 0x459d8800, 0x4707b900, 0x46699c00, 0x46792c00, 0x475c2800, 0x47293d00, 0x47168900, 0x45fb4800, 0x46a6be00, 0x46180c00, 0x4733a200, 0x477b0800, 0x47209b00, 0x46396c00, 0x4716d800, 0x44120000, 0x46e11200, 0x4708a100, 0x46809c00, 0x45b83000, 0x46245800, 0x46852600, 0x4653bc00, 0x46bf4a00, 0x472c0a00, 0x47705c00, 0x477efc00, 0x47101400, 0x46f1fc00, 0x47700800, 0x474f7200, 0x4737bd00, 0x44e9c000, 0x477bb700, 0x471b4100, 0x46a6ce00, 0x47654000, 0x468ce800, 0x477d8600, 0x46a5cc00, 0x4727bc00, 0x46cc9400, 0x472cc600, 0x4772ae00, 0x471c4200, 0x4758ad00, 0x474a6400, 0x471b3200, 0x45095000, 0x47751300, 0x46dcac00, 0x4740bf00, 0x4727c300, 0x46b79000, 0x477f0500, 0x467df000, 0x4733b300, 0x470bc800, 0x474ada00, 0x461bc400, 0x46ac7400, 0x4743d100, 0x474f9500, 0x47111d00, 0x45b94800, 0x47478d00, 0x47049900, 0x46c92800, 0x466c1800, 0x47561000, 0x46f58e00, 0x461f3000, 0x477f1900, 0x45466000, 0x434d0000, 0x44074000, 0x477d4a00, 0x47367d00, 0x47126600, 0x472fd000, 0x470f6600, 0x47638c00, 0x46d58c00, 0x4687b200, 0x46d45600, 0x4726bf00, 0x46bede00, 0x46f9a200, 0x46850e00, 0x467fc800, 0x45491000, 0x42380000, 0x46911e00, 0x470df300, 0x474ac500, 0x4739ba00, 0x46a25c00, 0x4749cf00, 0x46031000, 0x45eae800, 0x473a3400, 0x47129600, 0x4680a800, 0x4748bd00, 0x44f3c000, 0x4609d800, 0x460e6400, 0x46882a00, 0x46e50400, 0x46edc200, 0x470cb800, 0x46afca00, 0x477e6800, 0x46dd2a00, 0x462e7c00, 0x475de100, 0x45119000, 0x4721f000, 0x46ebc000, 0x45cc1000, 0x473e1b00, 0x46602800, 0x45a11000, 0x46b9d800, 0x46dc8000, 0x473b3700, 0x4764f900, 0x46e86c00, 0x467cc400, 0x471f8800, 0x474e4b00, 0x472c6400, 0x469fd600, 0x469ac000, 0x470f0900, 0x47601000, 0x467c8c00, 0x46fe9000, 0x47102000, 0x47570900, 0x474d4700, 0x4728d300, 0x475fbe00, 0x47792000, 0x4699d000, 0x476d6300, 0x458a8800, 0x45a7a000, 0x46565000, 0x466c7000, 0x47563100, 0x470fa900, 0x46e79e00, 0x47421d00, 0x469e5000, 0x44be4000, 0x46851000, 0x46ae0a00, 0x475a5900, 0x4738bb00, 0x46144000, 0x46e7fa00, 0x44cb4000, 0x47088b00, 0x471e0000, 0x47723e00, 0x46345800, 0x47551e00, 0x46355000, 0x472fc200, 0x47332100, 0x472d5700, 0x46ca1e00, 0x474b2600, 0x4706d400, 0x468cb600, 0x46d23600, 0x475c6600, 0x46335800, 0x467bf400, 0x47754700, 0x46ebe800, 0x46b54a00, 0x47762c00, 0x468bd400, 0x47213300, 0x46ac3a00, 0x44298000, 0x4727ed00, 0x47613e00, 0x473a5300, 0x477c2d00, 0x462eb000, 0x4702af00, 0x44060000, 0x4752ab00, 0x47258600, 0x4755f200, 0x469ec200, 0x475b4700, 0x468f2e00, 0x46939000, 0x4708e400, 0x474b5c00, 0x4731d900, 0x46cc0200, 0x47304600, 0x46447000, 0x46c59400, 0x461ef000, 0x468aba00, 0x47597800, 0x46730c00, 0x4767ef00, 0x47637500, 0x47186600, 0x46f9be00, 0x471a9a00, 0x474d3f00, 0x45a49000, 0x477e7d00, 0x47655d00, 0x474e8500, 0x460f0400, 0x46f40c00, 0x4611f000, 0x47019100, 0x471e3f00, 0x46c62000, 0x46494c00, 0x475d9700, 0x46e68600, 0x4655d000, 0x4641ac00, 0x46620800, 0x4763c200, 0x47708f00, 0x4746c300, 0x458f6800, 0x45863800, 0x46d29600, 0x46deea00, 0x470b9400, 0x4776d400, 0x477a8300, 0x47514b00, 0x44c38000, 0x41900000, 0x472f6a00, 0x46122000, 0x477fa400, 0x46715c00, 0x46303800, 0x46865200, 0x46d42800, 0x4681ea00, 0x46c1a800, 0x4603d400, 0x46e0ac00, 0x46a39600, 0x47277c00, 0x47293b00, 0x468b6000, 0x438d0000, 0x4761ef00, 0x466b1400, 0x47474f00, 0x472a6000, 0x473d9b00, 0x44370000, 0x47550800, 0x465f9000, 0x466ab000, 0x440e4000, 0x47270b00, 0x45d31800, 0x47518100, 0x474f9000, 0x476f9200, 0x46c83400, 0x46702800, 0x47292c00, 0x45f40000, 0x45bcf000, 0x476da400, 0x46bd4800, 0x4752d600, 0x46b88e00, 0x46fef400, 0x46da5c00, 0x46c98a00, 0x4734fd00, 0x47164b00, 0x4530c000, 0x4676c400, 0x47052e00, 0x46c09200, 0x46dab800, 0x47006400, 0x476a6d00, 0x471aec00, 0x471a1300, 0x4731b500, 0x449c6000, 0x46298c00, 0x47670f00, 0x46eda200, 0x46e1f800, 0x476b9c00, 0x473f6800, 0x45ced800, 0x47783700, 0x44c3c000, 0x4687be00, 0x47564300, 0x4702d800, 0x465e9400, 0x47060700, 0x47042100, 0x47072c00, 0x4754f500, 0x460b1800, 0x46bab400, 0x46c67e00, 0x46a73600, 0x45e97800, 0x475e0600, 0x46f58600, 0x46ac7400, 0x4699aa00, 0x475ef000, 0x46c9fa00, 0x475bbb00, 0x472a1a00, 0x45687000, 0x45bef800, 0x47572600, 0x47442a00, 0x4768c400, 0x46aa2e00, 0x46f4e800, 0x46b4a400, 0x45c5f000, 0x4498e000, 0x46a12800, 0x47308800, 0x452a7000, 0x46acce00};

int send_dma_pixels() {

	// Initialize DMA 1
	int status = initialize_dma(&AxiDma1, XPAR_AXI_DMA_1_DEVICE_ID);
	if(status != XST_SUCCESS) {
		print("Failed to initialize DMA 1 \n");
		return XST_FAILURE;
	}

	xil_printf("Sending %d bytes via DMA 0 \n", sizeof(pixels_data));
	dma_disable_all_interrupts(&AxiDma1);

	const int transaction_length = sizeof(pixels_data);
	volatile uint8_t* send_transaction_start = ram;

	// Copy to RAM
	memcpy(send_transaction_start, pixels_data, transaction_length);

	// Read out first element of RAM
	volatile uint32_t* tc_data = ram;

	const int num_first_values = 5;

	xil_printf("Printing %d first values to send via DMA 0 \n", num_first_values);

	for(int i = 0; i < num_first_values; ++i) {
		xil_printf("Value number %d is %p\n", i, tc_data[i]);
	}

	const int num_last_values = 5;
	xil_printf("Printing %d last values to send via DMA 0 \n", num_last_values);

	const int num_total_values = transaction_length / sizeof(uint32_t);

	for(int i = num_total_values - num_first_values; i < num_total_values; i++) {
		xil_printf("Value number %d is %p\n", i, tc_data[i]);
	}

	// Flush caches
	Xil_DCacheFlushRange((UINTPTR)send_transaction_start, transaction_length);

	status = XAxiDma_SimpleTransfer(&AxiDma1, send_transaction_start, transaction_length, XAXIDMA_DMA_TO_DEVICE);

	if (status != XST_SUCCESS) {
		print("XAxiDma1 simple transfer failed \n");
		return XST_FAILURE;
	}

	print("XAxiDma1 simple transfer transfer started\n");

	while (XAxiDma_Busy(&AxiDma1, XAXIDMA_DMA_TO_DEVICE)) {
					/* Wait */
	}

	print("DMA1 transfer finished! \n");

	return XST_SUCCESS;
}

const uint32_t expected_vals[] = {0xb3fbf080, 0xb6534019, 0xb658e031, 0xb6cbc629, 0xb69f48bc, 0xb73b80ed, 0x32ca5460, 0xb645f1dc, 0x36a61511, 0xb636b2e8, 0xb69aed87, 0xb5ee5bab, 0x36a09133, 0x36c47397, 0x36a717d7, 0x36c495e8, 0x360d6e18, 0x371408a3, 0xb6554c82, 0xb68e34b5, 0xb70771ec, 0x35edec8b, 0x3637e3a2, 0x36067b69, 0x36fb38cc, 0x36b51e17, 0x36c5e2fe, 0x361cfad6, 0x3668200f, 0x3642ae06, 0xb69af94a, 0x36a722da, 0x3593203a};

int recv_w_matrix() {
	volatile uint8_t* recv_transaction_start = ram + 0x10000;

	const int transaction_length = sizeof(expected_vals);

	// Flush caches
	Xil_DCacheFlushRange((UINTPTR)recv_transaction_start, transaction_length);
	int status = XAxiDma_SimpleTransfer(&AxiDma1, recv_transaction_start, transaction_length, XAXIDMA_DEVICE_TO_DMA);

	if (status != XST_SUCCESS) {
		print("XAxiDma1 simple transfer recv failed \n");
		return XST_FAILURE;
	}

	print("XAxiDma1 recv transfer started\n");

	while (XAxiDma_Busy(&AxiDma1, XAXIDMA_DEVICE_TO_DMA)) {
					/* Wait */
	}

	print("DMA1 recv transfer finished! \n");

	print("\n");

	for(int i = 0; i < transaction_length / sizeof(uint32_t); ++i) {
		xil_printf("Value number %d is %p\n", i, ((uint32_t*)recv_transaction_start)[i]);
	}

	print("\n");

	// Check values
	int correct = 1;

	for(int i = 0; i < transaction_length / sizeof(uint32_t); ++i) {
		uint32_t actual_val = ((uint32_t*)recv_transaction_start)[i];
		if (actual_val != expected_vals[i]) {
			xil_printf("ERROR ON VALUE %d, expected=%p, actual=%p", expected_vals[i], actual_val);
			correct = 0;
		}
	}

	if (correct) {
		print("ALL VALUES ARE CORRECT! \n");
	}


	return XST_SUCCESS;
}

void wait_until_accelerator_finishes() {
	print("Waiting for accelerator finished interrupt... \n");
	while(!accelerator_finished) {
		/* wait */
	}
	print("Accelerator finished! \n");
}

int main()
{
    init_platform();

    print("Bienvenido a nuevo codigo\n");

    if (print_version() != XST_SUCCESS) {
    	print("Version printing FAILED! \n");
    }

//    if (test_dma() != XST_SUCCESS) {
//    	print("DMA test FAILED\n");
//    }

    if (send_dma_tc_data() != XST_SUCCESS) {
    	print("Sending TC data FAILED! \n");
    }

//    usleep(1000000);

    print("Sending Pixels...\n");

    if (send_dma_pixels() != XST_SUCCESS) {
    	print("Sending pixels FAILED! \n");
    }

//    usleep(1000000);
    wait_until_accelerator_finishes();


    if (recv_w_matrix() != XST_SUCCESS) {
    	print("Reading W matrix FAILED! \n");
    }

//    if (ram_check_test() != XST_SUCCESS) {
//    	print("RAM test FAILED\n");
//    }

	int Status = XGpio_Initialize(&Gpio, XPAR_GPIO_0_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("Doh: Gpio Initialization Failed\n");
		return XST_FAILURE;
	}

	XGpio_SetDataDirection(&Gpio, LED_CHANNEL, ~LED);

    uint8_t led_status = 1;

	while (1) {

		/* Set the LED to High */
		XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, led_status);

		led_status = rotate_left(led_status, 1);

		/* Wait a small amount of time so the LED is visible */
		for (long Delay = 0; Delay < LED_DELAY; Delay++);
	}


    cleanup_platform();
    return 0;
}
