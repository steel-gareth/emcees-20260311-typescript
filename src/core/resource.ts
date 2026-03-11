// File generated from our OpenAPI spec by Stainless. See CONTRIBUTING.md for details.

import type { TheEmceesProject } from '../client';

export abstract class APIResource {
  protected _client: TheEmceesProject;

  constructor(client: TheEmceesProject) {
    this._client = client;
  }
}
