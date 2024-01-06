//
//  ViewController.swift
//  lab_03
//
//  Created by Ramesh Abeysekara on 2023-11-09.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var weatherConditionImage: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    
    let locationManager = CLLocationManager()
    private var searchedCitiesWeatherResponses: [WeatherResponse] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        fetchWeatherDataForLocation(location)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func fetchWeatherDataForLocation(_ location: CLLocation) {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        loadWeather(search: "\(latitude),\(longitude)")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loadWeather(search: searchTextField.text)
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToScreen2" {
            if let destinationVC = segue.destination as? Screen2ViewController {
                destinationVC.items = searchedCitiesWeatherResponses.map { weatherResponse in
                    return Cities(cityName: weatherResponse.location.name, temperature: "\(weatherResponse.current.temp_c) °C", icon: UIImage(systemName: getSymbolName(for: weatherResponse.current.condition.code)))
                }
            }
        }
    }
    
    @IBAction func citiesTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToScreen2", sender: self)
    }
    
    @IBAction func onLocationTapped(_ sender: UIButton) {
        resetFields()
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        resetFields()
        loadWeather(search: searchTextField.text)
    }
    
    private func resetFields() {
        locationLabel.text = ""
        temperatureLabel.text = ""
        conditionLabel.text = ""
        weatherConditionImage.image = nil
    }
    
    private func loadWeather(search: String?){
        guard let search = search else {
            return
        }
        
        guard let url = getUrl(query: search) else {
            print("Could not get URL")
            return
        }
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: url) { data, response, error in
            print("Network call complete")
            
            guard error == nil else {
                print("Received error")
                return
            }
            
            guard let data = data else {
                print("No data found")
                return
            }
            
            if let weatherResponse = self.parseJson(data: data) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                if let localTime = dateFormatter.date(from: weatherResponse.location.localtime) {
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: localTime)
                    
                    let colorSet: UIColor
                    switch hour {
                    case 0..<5:
                        colorSet = UIColor(hex: "1F2124")
                    case 5..<10:
                        colorSet = UIColor(hex: "313439")
                    case 10..<15:
                        colorSet = UIColor(hex: "43484e")
                    case 15..<20:
                        colorSet = UIColor(hex: "555b63")
                    default:
                        colorSet = UIColor(hex: "1F2124")
                    }
                    
                    DispatchQueue.main.async {
                        self.view.backgroundColor = colorSet
                        
                        self.locationLabel.text = weatherResponse.location.name
                        if !weatherResponse.location.region.isEmpty {
                            self.locationLabel.text! += " (\(weatherResponse.location.region))"
                        }
                        self.temperatureLabel.text = "\(weatherResponse.current.temp_c) °C"
                        self.conditionLabel.text = weatherResponse.current.condition.text
                        
                        let weatherCode = weatherResponse.current.condition.code
                        let weatherSymbolName = self.getSymbolName(for: weatherCode)
                        
                        let config = UIImage.SymbolConfiguration(paletteColors: [.white, .systemCyan, .systemYellow])
                        self.weatherConditionImage.preferredSymbolConfiguration = config
                        self.weatherConditionImage.image = UIImage(systemName: weatherSymbolName)
                    }
                }
                self.searchedCitiesWeatherResponses.append(weatherResponse)
            }
        }
        
        dataTask.resume()
    }
    
    private func getUrl(query: String)->URL?{
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "2c42db8054ea43ed881162428231811"
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: url)
    }
    
    private func parseJson(data: Data) -> WeatherResponse? {
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        do {
            weather = try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("Error decoding \(error)")
        }
        return weather
    }
    
    @IBAction func showTempInF(_ sender: UISwitch) {
        if sender.isOn {
            if let currentTemp = Float(temperatureLabel.text?.replacingOccurrences(of: " °C", with: "") ?? "0") {
                let fahrenheitTemp = (currentTemp * 9/5) + 32
                temperatureLabel.text = String(format: "%.2f", fahrenheitTemp) + " °F"
            }
        } else {
            if let currentTemp = Float(temperatureLabel.text?.replacingOccurrences(of: " °F", with: "") ?? "0") {
                let celsiusTemp = (currentTemp - 32) * 5/9
                temperatureLabel.text = String(format: "%.2f", celsiusTemp) + " °C"
            }
        }
    }
    
    private func getSymbolName(for weatherCode: Int) -> String {
        switch weatherCode {
        case 1000:
            return "sun.max.fill"
        case 1003:
            return "cloud.sun.fill"
        case 1006:
            return "cloud.fill"
        case 1009:
            return "cloud.fog.fill"
        case 1030:
            return "cloud.fog.fill"
        case 1063, 1066, 1069, 1072:
            return "cloud.drizzle.fill"
        case 1087:
            return "cloud.bolt.rain.fill"
        case 1114, 1117:
            return "wind.snow"
        case 1135, 1147:
            return "cloud.fog.fill"
        case 1150, 1153, 1168, 1171:
            return "cloud.drizzle.fill"
        case 1180, 1183, 1186, 1189, 1192, 1195:
            return "cloud.rain.fill"
        case 1198, 1201:
            return "cloud.hail.fill"
        case 1204, 1207:
            return "cloud.sleet.fill"
        case 1210, 1213, 1216, 1219, 1222, 1225:
            return "cloud.snow.fill"
        case 1237, 1240, 1243, 1246:
            return "cloud.rain.fill"
        case 1249, 1252, 1255, 1258, 1261, 1264:
            return "cloud.sleet.fill"
        case 1273, 1276, 1279, 1282:
            return "cloud.bolt.rain.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name: String
    let region: String
    let localtime: String
}

struct Weather: Decodable {
    let temp_c: Float
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        var rgb: UInt64 = 0
        
        if hexSanitized.hasPrefix("#") {
            hexSanitized = String(hexSanitized.dropFirst())
        }
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
