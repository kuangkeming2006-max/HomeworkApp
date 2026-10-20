"""Read native XCTest PNG display dimensions, including its EXIF orientation."""
import struct
import zlib


def _orientation(payload):
    if payload.startswith(b"Exif\x00\x00"):
        payload = payload[6:]
    if len(payload) < 8 or payload[:2] not in (b"II", b"MM"):
        raise ValueError("Invalid PNG EXIF byte order")
    endian = "<" if payload[:2] == b"II" else ">"
    if struct.unpack_from(endian + "H", payload, 2)[0] != 42:
        raise ValueError("Invalid PNG EXIF header")
    offset = struct.unpack_from(endian + "I", payload, 4)[0]
    if offset + 2 > len(payload):
        raise ValueError("Truncated PNG EXIF directory")
    count = struct.unpack_from(endian + "H", payload, offset)[0]
    if offset + 2 + count * 12 > len(payload):
        raise ValueError("Truncated PNG EXIF entries")
    for index in range(count):
        position = offset + 2 + index * 12
        tag, value_type, number = struct.unpack_from(endian + "HHI", payload, position)
        if tag == 0x0112:
            if value_type != 3 or number != 1:
                raise ValueError("Invalid PNG orientation field")
            value = struct.unpack_from(endian + "H", payload, position + 8)[0]
            if value not in range(1, 9):
                raise ValueError("Invalid PNG orientation value")
            return value
    return 1


def png_dimensions(payload):
    if payload[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("Invalid PNG signature")
    offset, width, height, orientation = 8, None, None, 1
    while offset + 12 <= len(payload):
        length = struct.unpack_from(">I", payload, offset)[0]
        end = offset + 12 + length
        if end > len(payload):
            raise ValueError("Truncated PNG chunk")
        kind = payload[offset + 4:offset + 8]
        data = payload[offset + 8:offset + 8 + length]
        crc = struct.unpack_from(">I", payload, offset + 8 + length)[0]
        if zlib.crc32(kind + data) & 0xFFFFFFFF != crc:
            raise ValueError("Invalid PNG chunk checksum")
        if kind == b"IHDR":
            if length != 13:
                raise ValueError("Invalid PNG image header")
            width, height = struct.unpack_from(">II", data)
        elif kind == b"eXIf":
            orientation = _orientation(data)
        offset = end
        if kind == b"IEND":
            break
    if not width or not height:
        raise ValueError("PNG is missing image dimensions")
    displayed = (height, width) if orientation in (5, 6, 7, 8) else (width, height)
    return {"pixelWidth": width, "pixelHeight": height, "exifOrientation": orientation,
            "displayWidth": displayed[0], "displayHeight": displayed[1]}
