package io.hanko.client.java.json;

import java.io.InputStream;

public interface HankoJsonParser {
    <T> T parse(InputStream is, Class<T> valueType);
}