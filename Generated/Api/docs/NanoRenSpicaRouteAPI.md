# NanoRenSpicaRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**nanoRenSpica**](NanoRenSpicaRouteAPI.md#nanorenspica) | **POST** /nano_ren_spica | 


# **nanoRenSpica**
```swift
    open class func nanoRenSpica(audio: String, id: UUID, image: String, prompt: String, status: Status, userId: String, credit: Int64? = nil, file: String? = nil, requestId: String? = nil, completion: @escaping (_ data: NanoRenSpica?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let audio = "audio_example" // String | 
let id = 987 // UUID | 
let image = "image_example" // String | 
let prompt = "prompt_example" // String | 
let status = Status() // Status | 
let userId = "userId_example" // String | 
let credit = 987 // Int64 |  (optional)
let file = "file_example" // String |  (optional)
let requestId = "requestId_example" // String |  (optional)

NanoRenSpicaRouteAPI.nanoRenSpica(audio: audio, id: id, image: image, prompt: prompt, status: status, userId: userId, credit: credit, file: file, requestId: requestId) { (response, error) in
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
 **audio** | **String** |  | 
 **id** | **UUID** |  | 
 **image** | **String** |  | 
 **prompt** | **String** |  | 
 **status** | [**Status**](Status.md) |  | 
 **userId** | **String** |  | 
 **credit** | **Int64** |  | [optional] 
 **file** | **String** |  | [optional] 
 **requestId** | **String** |  | [optional] 

### Return type

[**NanoRenSpica**](NanoRenSpica.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

