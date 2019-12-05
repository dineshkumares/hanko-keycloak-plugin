export const convertToBinary = (dataURI: string) => {
  var raw = window.atob(dataURI)
  var rawLength = raw.length
  var array = new Uint8Array(new ArrayBuffer(rawLength))

  for (let i = 0; i < rawLength; i++) {
    array[i] = raw.charCodeAt(i)
  }
  return array
}

export const arrayBufferToBase64Url = (buf: ArrayBuffer) => {
  var binary = ''
  var bytes = new Uint8Array(buf)
  var len = bytes.byteLength
  for (var i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return window
    .btoa(binary)
    .replace(/\//g, '_')
    .replace(/\+/g, '-')
}

export const base64UrlToArrayBuffer = (data: string) => {
  let input = data.replace(/-/g, '+')
    .replace(/_/g, '/')

  return convertToBinary(input)
}

export const decodeRegistrationRequest = (request: any) => {
  var newRequest = request
  newRequest.user.id = base64UrlToArrayBuffer(request.user.id)
  newRequest.challenge = base64UrlToArrayBuffer(request.challenge)
  newRequest.excludeCredentials = request.excludeCredentials.map(function (cred: any) {
    return {
      id: base64UrlToArrayBuffer(cred.id),
      type: cred.type,
      transports: cred.transports
    }
  })

  return newRequest
}

export const encodeRegistrationResult = (data: any) => {
  var d: any = {}
  d.response = {}
  d.id = data.id
  d.rawId = arrayBufferToBase64Url(data.rawId)
  d.type = data.type
  d.response.attestationObject = arrayBufferToBase64Url(data.response.attestationObject)
  d.response.clientDataJSON = arrayBufferToBase64Url(data.response.clientDataJSON)

  return d
}