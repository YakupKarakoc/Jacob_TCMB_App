import UIKit

class ViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var fromPicker: UIPickerView!
    @IBOutlet weak var toPicker: UIPickerView!
    @IBOutlet weak var calculateButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    private var currencyList: [Currency] = []
    private var filteredList: [Currency] = []
    private var isSearching = false

    private var selectedFromIndex = 0
    private var selectedToIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Delegate/DataSource ayarları
        fromPicker.delegate   = self
        fromPicker.dataSource = self
        toPicker.delegate     = self
        toPicker.dataSource   = self
        

        tableView.delegate    = self
        tableView.dataSource  = self

        searchBar.delegate    = self
        searchBar.placeholder = "Döviz kodu ara..."
        searchBar.showsCancelButton = true

        resultLabel.text = ""
        fetchAndSetupCurrencies()
    }

    // MARK: - Data Fetch
    private func fetchAndSetupCurrencies() {
        CurrencyService().fetch { [weak self] list in
            guard let self = self else { return }
            // En başa Türk Lirası ekle
            let listWithTRY = [Currency(code: "TRY",
                                        name: "Türk Lirası",
                                        forexBuying: 1.0,
                                        forexSelling: 1.0)] + list
            self.currencyList = listWithTRY
            DispatchQueue.main.async {
                self.fromPicker.reloadAllComponents()
                self.toPicker.reloadAllComponents()
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Actions

    @IBAction func calculateTapped(_ sender: UIButton) {
        view.endEditing(true)
        guard let raw = amountTextField.text?
                                .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            resultLabel.text = "Lütfen bir miktar girin."
            return
        }
        let allowed = CharacterSet(charactersIn: "0123456789.,")
        let cleaned = raw.unicodeScalars
                         .filter { allowed.contains($0) }
                         .map(String.init)
                         .joined()
        let normalized = cleaned.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalized) else {
            resultLabel.text = "Geçersiz miktar."
            return
        }

        let from = currencyList[selectedFromIndex]
        let to   = currencyList[selectedToIndex]
        let tryAmount = amount * from.forexBuying
        let converted = tryAmount / to.forexSelling
        let formatted = String(format: "%.4f", converted)

        resultLabel.text = "\(cleaned) \(from.code) = \(formatted) \(to.code)"
    }

    @IBAction func resetTapped(_ sender: UIButton) {
        // Debug
        print("🔄 resetTapped tetiklendi")

        // 1) TextField’i temizle
        amountTextField.text = ""
        // 2) Seçimleri başa al
        selectedFromIndex = 0
        selectedToIndex   = 0
        fromPicker.selectRow(0, inComponent: 0, animated: true)
        toPicker.selectRow(0,   inComponent: 0, animated: true)
        // 3) Picker’ları yeniden yükle
        fromPicker.reloadAllComponents()
        toPicker.reloadAllComponents()
        // 4) Sonuç label’ını sıfırla
        resultLabel.text = ""
        // 5) Aramayı sıfırla
        isSearching  = false
        filteredList = []
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.reloadData()
        // 6) Klavyeyi tekrar odakla
        amountTextField.becomeFirstResponder()
    }
}

// MARK: - UIPickerView
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        currencyList.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        currencyList[row].code
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == fromPicker {
            selectedFromIndex = row
        } else {
            selectedToIndex = row
        }
    }
}

// MARK: - UITableView
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredList.count : currencyList.count
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = isSearching ? filteredList : currencyList
        let c = list[indexPath.row]
        let cell = tv.dequeueReusableCell(withIdentifier: "CurrencyCell", for: indexPath)
        cell.textLabel?.text       = c.code
        cell.detailTextLabel?.text = "Alış: \(c.forexBuying)  Satış: \(c.forexSelling)"
        return cell
    }
}

// MARK: - UISearchBar
extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange query: String) {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            isSearching  = false
            filteredList = []
        } else {
            isSearching  = true
            filteredList = currencyList.filter {
                $0.code.lowercased().contains(text.lowercased())
            }
        }
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching  = false
        filteredList = []
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
}

