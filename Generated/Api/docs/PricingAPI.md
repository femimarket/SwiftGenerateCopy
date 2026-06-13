# PricingAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**pricingRoute**](PricingAPI.md#pricingroute) | **POST** /pricing_route | 


# **pricingRoute**
```swift
    open class func pricingRoute(artist: Int64, audio: Int64, chat: Int64, creator: Int64, director: Int64, falFlux2Pro: Int64, falNanoBanana2: Int64, falZImageTurbo: Int64, gb: Int64, generate: Int64, id: UUID, image: Int64, lyricSync: Int64, microPixLyra: Int64, microPixVega: Int64, nanoPixLuna: Int64, nanoRenSpica: Int64, question: Int64, summary: Int64, upload: Int64, completion: @escaping (_ data: Pricing?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let artist = 987 // Int64 | 
let audio = 987 // Int64 | 
let chat = 987 // Int64 | 
let creator = 987 // Int64 | 
let director = 987 // Int64 | 
let falFlux2Pro = 987 // Int64 | 
let falNanoBanana2 = 987 // Int64 | 
let falZImageTurbo = 987 // Int64 | 
let gb = 987 // Int64 | 
let generate = 987 // Int64 | 
let id = 987 // UUID | 
let image = 987 // Int64 | 
let lyricSync = 987 // Int64 | 
let microPixLyra = 987 // Int64 | 
let microPixVega = 987 // Int64 | 
let nanoPixLuna = 987 // Int64 | 
let nanoRenSpica = 987 // Int64 | 
let question = 987 // Int64 | 
let summary = 987 // Int64 | 
let upload = 987 // Int64 | 

PricingAPI.pricingRoute(artist: artist, audio: audio, chat: chat, creator: creator, director: director, falFlux2Pro: falFlux2Pro, falNanoBanana2: falNanoBanana2, falZImageTurbo: falZImageTurbo, gb: gb, generate: generate, id: id, image: image, lyricSync: lyricSync, microPixLyra: microPixLyra, microPixVega: microPixVega, nanoPixLuna: nanoPixLuna, nanoRenSpica: nanoRenSpica, question: question, summary: summary, upload: upload) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **artist** | **Int64** |  | 
 **audio** | **Int64** |  | 
 **chat** | **Int64** |  | 
 **creator** | **Int64** |  | 
 **director** | **Int64** |  | 
 **falFlux2Pro** | **Int64** |  | 
 **falNanoBanana2** | **Int64** |  | 
 **falZImageTurbo** | **Int64** |  | 
 **gb** | **Int64** |  | 
 **generate** | **Int64** |  | 
 **id** | **UUID** |  | 
 **image** | **Int64** |  | 
 **lyricSync** | **Int64** |  | 
 **microPixLyra** | **Int64** |  | 
 **microPixVega** | **Int64** |  | 
 **nanoPixLuna** | **Int64** |  | 
 **nanoRenSpica** | **Int64** |  | 
 **question** | **Int64** |  | 
 **summary** | **Int64** |  | 
 **upload** | **Int64** |  | 

### Return type

[**Pricing**](Pricing.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

