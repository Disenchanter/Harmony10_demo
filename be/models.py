from typing import List, Optional, Dict, Union
from pydantic import BaseModel, Field, validator
from enum import Enum


class ModeEnum(str, Enum):
    HARMONIZE = "harmonize"
    EVALUATE = "evaluate"


class ReturnModeEnum(str, Enum):
    BYTES = "bytes"
    URL = "url"


class QuantizeEnum(str, Enum):
    ONE_SECOND = "1s"


class KeyEnum(str, Enum):
    C_MAJOR = "C major"


class OctaveBaseEnum(str, Enum):
    C4 = "C4"


class MusicEvent(BaseModel):
    t_sec: int = Field(..., ge=0, le=60, description="Time in seconds (0-60)")  # Extended to 60 seconds
    note: int = Field(..., description="MIDI note number")
    vel: Optional[int] = Field(96, ge=1, le=127, description="Velocity (1-127), default 96")

    @validator('note')
    def validate_note(cls, v):
        # C major white keys: C(60), D(62), E(64), F(65), G(67), A(69), B(71)
        white_keys = {60, 62, 64, 65, 67, 69, 71}
        if v not in white_keys:
            raise ValueError(f"Note must be one of C major white keys: {white_keys}")
        return v


class BaseRequest(BaseModel):
    version: str = Field(..., description="API version")
    mode: ModeEnum = Field(..., description="Operation mode")
    duration_sec: int = Field(..., ge=1, le=60, description="Duration in seconds (1-60)")
    quantize: QuantizeEnum = Field(..., description="Quantization setting")
    octave_base: OctaveBaseEnum = Field(..., description="Base octave")
    key: KeyEnum = Field(..., description="Musical key")
    events: List[MusicEvent] = Field(..., min_items=1, description="List of music events")

    @validator('version')
    def validate_version(cls, v):
        if v != "1.0":
            raise ValueError("Unsupported version")
        return v

    @validator('events')
    def validate_events(cls, v):
        if not v:
            raise ValueError("Empty sequence")
        
        # Check for duplicate timeslots
        time_slots = [event.t_sec for event in v]
        if len(time_slots) != len(set(time_slots)):
            raise ValueError("Duplicate timeslot")
        
        return v


class HarmonizeRequest(BaseRequest):
    mode: ModeEnum = Field(ModeEnum.HARMONIZE, description="Must be 'harmonize'")
    return_mode: ReturnModeEnum = Field(ReturnModeEnum.BYTES, description="Return format")

    @validator('mode')
    def validate_mode(cls, v):
        if v != ModeEnum.HARMONIZE:
            raise ValueError("Invalid mode")
        return v


class EvaluateRequest(BaseRequest):
    mode: ModeEnum = Field(ModeEnum.EVALUATE, description="Must be 'evaluate'")
    reference_id: str = Field(..., description="Reference template ID")

    @validator('mode')
    def validate_mode(cls, v):
        if v != ModeEnum.EVALUATE:
            raise ValueError("Invalid mode")
        return v


class EvaluateResponse(BaseModel):
    score: float = Field(..., ge=0, le=100, description="Overall score (0-100)")
    subscores: Dict[str, float] = Field(..., description="Detailed subscores")
    mistakes: List[Dict[str, Union[int, str]]] = Field(..., description="List of mistakes")
    advice: str = Field(..., description="Advice for improvement")


class ErrorResponse(BaseModel):
    error_code: str = Field(..., description="Error code")
    message: str = Field(..., description="Error message")
    details: Optional[Dict] = Field(None, description="Additional error details")