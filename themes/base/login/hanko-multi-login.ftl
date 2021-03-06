<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=true; section>
    <#if section = "title">
        <#if loginMethod = "PASSWORD">
            Sign in with Password
        <#elseif loginMethod = "UAF">
            Sign in with HANKO Authenticator
        <#elseif loginMethod = "WEBAUTHN">
            Sign in with WebAuthn
        </#if>
    <#elseif section = "header">
        <#if loginMethod = "PASSWORD">
            ${msg("signInPassword")}
        <#elseif loginMethod = "UAF">
            ${msg("signInAuthenticator")}
        <#elseif loginMethod = "WEBAUTHN">
            ${msg("signInWebAuthn")}
        </#if>
    <#elseif section = "form">

        <#if loginMethod = "PASSWORD">
            <form id="kc-form-login" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">
                <div class="${properties.kcFormGroupClass!}">
                    <label for="password" class="${properties.kcLabelClass!}">${msg("password")}</label>
                    <input tabindex="2" id="password" class="${properties.kcInputClass!}" name="password"
                           type="password" autocomplete="off" autofocus />
                </div>
                <div class="${properties.kcFormOptionsWrapperClass!}">
                            <#if realm.resetPasswordAllowed>
                                <span><a tabindex="5" href="${url.loginResetCredentialsUrl}">${msg("doForgotPassword")}</a></span>
                            </#if>
                </div>
                <div id="kc-form-buttons" class="${properties.kcFormGroupClass!}">
                    <input tabindex="4" class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" name="login" id="kc-login" type="submit" value="${msg("doLogIn")}"/>
                </div>
                <input type="hidden" name="loginMethod" value="PASSWORD" />
            </form>
            <#include "hanko-multi-login-links.ftl">
        <#elseif loginMethod = "UAF">
            <p>${msg("signInDescriptionAuthenticator")}</p>

            <img src="${url.resourcesPath}/img/login-hanko.png" width="120" style="display: block; margin: 50px auto">

            <form action="${url.loginAction}" style="display:hidden" class="${properties.kcFFormClass!}"
                  id="kc-hanko-login-form"
                  method="post">
                <input type="hidden" name="loginMethod" value="UAF" />
            </form>

            <#include "hanko-multi-login-links.ftl">

            <script src="${url.resourcesPath}/js/hanko.js"></script>
            <script>
                const awaitLoginComplete = () => {
                    fetchWithTimeout(() => fetch('/auth/realms/${realm.name}/hanko/request/${requestId}'))
                            .then(response => response.json())
                            .catch(error => {
                                console.error('Error:', error)
                                setTimeout(function () {
                                    awaitLoginComplete();
                                }, 1000);
                            }).then(response => {
                        if (response.status === "PENDING") {
                            setTimeout(function () {
                                awaitLoginComplete();
                            }, 500);
                        } else {
                            document.getElementById('kc-hanko-login-form').submit();
                        }
                    });
                };
                window.onload = awaitLoginComplete;
            </script>
        <#elseif loginMethod = "WEBAUTHN">
            <p>${msg("signInDescriptionWebAuthn")}</p>

            <div class="flexrow">
                <div class="imgwrapper">
                    <img src="${url.resourcesPath}/img/windows-hello.png">
                </div>
                <div class="imgwrapper">
                    <img src="${url.resourcesPath}/img/yubikey.png">
                </div>
            </div>

            <form action="${url.loginAction}" style="display:hidden" class="${properties.kcFFormClass!}"
                  id="kc-hanko-login-form"
                  method="post">
                <input type="hidden" name="hankoresponse" id="hankoresponse" />
                <input type="hidden" name="loginMethod" value="WEBAUTHN" />
            </form>
            <script>
                var fidoRequest = JSON.parse('${request?no_esc}');

                function convertToBinary (dataURI) {
                  var raw = window.atob(dataURI)
                  var rawLength = raw.length
                  var array = new Uint8Array(new ArrayBuffer(rawLength))

                  for (let i = 0; i < rawLength; i++) {
                    array[i] = raw.charCodeAt(i)
                  }
                  return array
                }

                function arrayBufferToBase64Url(buf) {
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

                function base64UrlToArrayBuffer(data) {
                  let input = data.replace(/-/g, '+')
                    .replace(/_/g, '/')

                  return convertToBinary(input)
                }

                function decodeAuthenticationRequest(request) {
                  var newRequest = request
                  newRequest.challenge = base64UrlToArrayBuffer(request.challenge)
                  newRequest.allowCredentials = request.allowCredentials.map(function (cred) {
                    return {
                      id: base64UrlToArrayBuffer(cred.id),
                      type: cred.type,
                      transports: cred.transports
                    }
                  })

                  return newRequest
                }

                function encodeAuthenticationResult(data) {
                  var d = {}
                  d.response = {}
                  d.rawId = arrayBufferToBase64Url(data.rawId)
                  d.id = data.id
                  d.type = data.type
                  d.response.clientDataJSON = arrayBufferToBase64Url(data.response.clientDataJSON)
                  d.response.authenticatorData = arrayBufferToBase64Url(data.response.authenticatorData)
                  d.response.signature = arrayBufferToBase64Url(data.response.signature)
                  d.response.userHandle = arrayBufferToBase64Url(data.response.userHandle)

                  return d
                }

                var getCredentialOptions = decodeAuthenticationRequest(fidoRequest)

<#--                  var challenge = Uint8Array.from(window.atob(fidoRequest.challenge), function (v) {
                    return v.charCodeAt(0);
                });

                var getCredentialOptions = {
                    challenge: challenge,
                    allowCredentials: fidoRequest.credID.map(function (id) {
                        return {
                            id: Uint8Array.from(window.atob(id.replace(/\_/g, "/").replace(/\-/g, "+")), function (v) {
                                return v.charCodeAt(0);
                            }),
                            type: "public-key",
                            transports: ["usb", "nfc", "ble", "internal"]
                        };
                    }),
                    rpId: document.domain,
                    timeout: 60000
                };

                function  arrayBufferToString(buf) {
                    return String.fromCharCode.apply(null, new Uint8Array(buf));
                }

                function arrayBufferToBase64Url(buf) {
                    var binary = '';
                    var bytes = new Uint8Array(buf);
                    var len = bytes.byteLength;
                    for (var i = 0; i < len; i++) {
                        binary += String.fromCharCode(bytes[i]);
                    }
                    return window.btoa(binary).replace(/\//g, "_").replace(/\+/g, "-");
                }

                function stringToArrayBuffer(str) {
                    var buf = new ArrayBuffer(str.length * 2);
                    var bufView = new Uint8Array(buf);
                    for (var i = 0, strLen = str.length; i < strLen; i++) {
                        bufView[i] = str.charCodeAt(i);
                    }
                    return buf;
                }  -->

                navigator.credentials.get({publicKey: getCredentialOptions})
                        .then(function (credentialResult) {
<#--                              var hankoResponse = {
                                credID: credentialResult.id.replace(/\//g, "_").replace(/\+/g, "-"),
                                credType: "public-key",
                                clientData: arrayBufferToBase64Url(credentialResult.response.clientDataJSON),
                                signature: arrayBufferToBase64Url(credentialResult.response.signature),
                                authenticatorData: arrayBufferToBase64Url(credentialResult.response.authenticatorData)
                            };  -->

                            var hankoResponse = encodeAuthenticationResult(credentialResult)

                            console.log(hankoResponse);
                            document.getElementById('hankoresponse').value = JSON.stringify(hankoResponse);
                            document.getElementById('kc-hanko-login-form').submit();
                        })
                        .catch(function (reason) {
                            console.error(reason)
                        });
            </script>
            <#include "hanko-multi-login-links.ftl">
        </#if>

    </#if>
</@layout.registrationLayout>
