import SwiftUI
import HealthKit

struct ContentView: View {
    private let healthStore = HKHealthStore()
    @State private var stepCount: String = "10000"
    @State private var statusMessage: String = "Chờ nhập liệu..."
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin số bước chân")) {
                    TextField("Nhập số bước", text: $stepCount)
                        .keyboardType(.numberPad)
                    
                    DatePicker("Thời gian", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    Button(action: {
                        requestAuthorizationAndInjectSteps()
                    }) {
                        Text("Tiêm số bước vào Apple Health")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }

                Section(header: Text("Trạng thái")) {
                    Text(statusMessage)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Health Injector")
        }
    }

    func requestAuthorizationAndInjectSteps() {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Thiết bị không hỗ trợ HealthKit!"
            return
        }

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            statusMessage = "Không thể khởi tạo loại dữ liệu bước chân!"
            return
        }

        let typesToShare: Set = [stepType]
        let typesToRead: Set = [stepType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                injectSteps()
            } else {
                DispatchQueue.main.async {
                    statusMessage = "Lỗi cấp quyền: \(error?.localizedDescription ?? "Không rõ")"
                }
            }
        }
    }

    func injectSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let stepsVal = Double(stepCount) else {
            DispatchQueue.main.async {
                statusMessage = "Số bước chân không hợp lệ!"
            }
            return
        }

        let unit = HKUnit.count()
        let quantity = HKQuantity(unit: unit, doubleValue: stepsVal)
        
        // Ghi trực tiếp dữ liệu vào HealthKit mà không qua bộ lọc tự động
        let sample = HKQuantitySample(type: stepType, quantity: quantity, start: selectedDate, end: selectedDate)

        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                if success {
                    statusMessage = "Đã bơm thành công \(Int(stepsVal)) bước!"
                } else {
                    statusMessage = "Lỗi khi lưu: \(error?.localizedDescription ?? "Không rõ")"
                }
            }
        }
    }
}
