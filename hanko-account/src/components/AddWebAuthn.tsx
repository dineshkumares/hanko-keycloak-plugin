import * as React from 'react'
import { fetchApi } from '../utils/fetchApi'
import {
  decodeRegistrationRequest,
  encodeRegistrationResult
} from '../utils/conversion'

type AddWebAuthnProps = {
  children: React.ReactNode
  keycloak: Keycloak.KeycloakInstance
  refetch: () => void
  type: 'roaming' | 'platform'
}

type AddWebAuthnState = {}

export class AddWebAuthn extends React.Component<
  AddWebAuthnProps,
  AddWebAuthnState
> {
  constructor(props: AddWebAuthnProps) {
    super(props)
    this.state = {}
  }

  addThisDevice = () => {
    const { keycloak, refetch, type } = this.props

    const authenticatorSelection =
      type == 'roaming'
        ? {
            requireResidentKey: false,
            userVerification: 'discouraged',
            authenticatorAttachment: 'cross-platform'
          }
        : {
            requireResidentKey: false,
            userVerification: 'required',
            authenticatorAttachment: 'platform'
          }

    // fetch request
    fetchApi(keycloak, '/hanko/registerType/WEBAUTHN', 'POST', {
      ...authenticatorSelection
    }).then(registrationRequest => {
      const fidoRequest = JSON.parse(registrationRequest.request)
      const pubKey = decodeRegistrationRequest(fidoRequest)
      const s = navigator as any

      s.credentials
        .create({ publicKey: pubKey })
        .then((result: any) => {
          let response = encodeRegistrationResult(result)
          fetchApi(
            keycloak,
            '/hanko/request/verify/webauthn',
            'POST',
            response
          ).then(result => {
            refetch()
          })
        })
        .catch((reason: any) => {
          console.error(reason)
        })
    })
  }

  render() {
    const { children } = this.props
    return <button onClick={this.addThisDevice}>{children}</button>
  }
}
