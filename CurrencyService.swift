import Foundation

class CurrencyService: NSObject {
    // MARK: - Dahili State
    private var currencies = [Currency]()
    private var currentElement = ""
    private var currentCode = ""
    private var currentName = ""
    private var currentBuying = ""
    private var currentSelling = ""
    private var completionHandler: (([Currency]) -> Void)?

    // MARK: - Public API
    func fetch(completion: @escaping ([Currency]) -> Void) {
        self.completionHandler = completion
        guard let url = URL(string: "https://www.tcmb.gov.tr/kurlar/today.xml") else {
            completion([]); return
        }
        // 1) Veriyi indir
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            // 2) XMLParser ile parse et
            let parser = XMLParser(data: data)
            parser.delegate = self
            let success = parser.parse()
            
            // 3) Parse bittiğinde sonuçları geri gönder
            DispatchQueue.main.async {
                if success {
                    completion(self.currencies)
                } else {
                    completion([])
                }
            }
        }.resume()
    }
}

// MARK: - XMLParserDelegate
extension CurrencyService: XMLParserDelegate {
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "Currency" {
            // Her yeni döviz kodu için değişkenleri sıfırla
            currentCode    = attributeDict["Kod"] ?? ""
            currentName    = ""
            currentBuying  = ""
            currentSelling = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        switch currentElement {
        case "Isim":
            currentName += trimmed
        case "ForexBuying":
            currentBuying += trimmed
        case "ForexSelling":
            currentSelling += trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        if elementName == "Currency" {
            // Virgülleri noktaya çevirip Double’a çevir
            let buy  = Double(currentBuying.replacingOccurrences(of: ",", with: ".")) ?? 0
            let sell = Double(currentSelling.replacingOccurrences(of: ",", with: ".")) ?? 0
            let currency = Currency(
                code:         currentCode,
                name:         currentName,
                forexBuying:  buy,
                forexSelling: sell
            )
            currencies.append(currency)
        }
        currentElement = ""
    }
}

