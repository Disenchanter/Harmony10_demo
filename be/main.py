from fastapi import FastAPI, HTTPException, Response
from fastapi.responses import JSONResponse
from pydantic import ValidationError
import logging
from typing import Union

from models import (
    HarmonizeRequest, EvaluateRequest, EvaluateResponse, 
    ErrorResponse, ModeEnum
)
from midi_utils import MidiGenerator, MusicEvaluator

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Music Harmony API",
    description="FastAPI backend for Flutter + Python music demo",
    version="1.0.0"
)

# 初始化服务
midi_generator = MidiGenerator()
music_evaluator = MusicEvaluator()


@app.exception_handler(ValidationError)
async def validation_exception_handler(request, exc):
    """处理 Pydantic 验证错误"""
    error_details = exc.errors()[0] if exc.errors() else {}
    error_msg = error_details.get('msg', 'Validation error')
    
    # 映射到具体的错误码
    error_code = "validation_error"
    if "Unsupported version" in error_msg:
        error_code = "unsupported_version"
    elif "Invalid mode" in error_msg:
        error_code = "invalid_mode"
    elif "duration_sec" in str(error_details):
        error_code = "invalid_duration"
    elif "quantize" in str(error_details):
        error_code = "invalid_quantize"
    elif "Empty sequence" in error_msg:
        error_code = "empty_sequence"
    elif "Duplicate timeslot" in error_msg:
        error_code = "duplicate_timeslot"
    elif "Note must be one of" in error_msg:
        error_code = "invalid_note"
    
    return JSONResponse(
        status_code=400,
        content=ErrorResponse(
            error_code=error_code,
            message=error_msg,
            details={"validation_errors": exc.errors()}
        ).model_dump()
    )


@app.exception_handler(ValueError)
async def value_error_handler(request, exc):
    """处理 ValueError"""
    error_msg = str(exc)
    error_code = "validation_error"
    
    if "Reference not found" in error_msg:
        error_code = "reference_not_found"
    elif "Unsupported version" in error_msg:
        error_code = "unsupported_version"
    elif "Invalid mode" in error_msg:
        error_code = "invalid_mode"
    elif "Empty sequence" in error_msg:
        error_code = "empty_sequence"
    elif "Duplicate timeslot" in error_msg:
        error_code = "duplicate_timeslot"
    elif "invalid_note" in error_msg.lower():
        error_code = "invalid_note"
    
    return JSONResponse(
        status_code=400,
        content=ErrorResponse(
            error_code=error_code,
            message=error_msg
        ).model_dump()
    )


@app.post("/api/v1/harmonize")
async def harmonize(request: HarmonizeRequest):
    """
    生成带和声的 MIDI 文件
    """
    try:
        logger.info(f"Processing harmonize request with {len(request.events)} events")
        
        # 验证请求
        if request.mode != ModeEnum.HARMONIZE:
            raise ValueError("Invalid mode")
        
        # 生成 MIDI 和和弦信息
        midi_bytes, chord_names_info = midi_generator.create_harmonized_midi(
            events=request.events,
            duration_sec=request.duration_sec
        )
        
        logger.info(f"Generated MIDI file with {len(midi_bytes)} bytes")
        logger.info(f"Generated chords: {[chord['chord_name'] for chord in chord_names_info]}")
        
        # 根据返回模式返回结果
        if request.return_mode == "bytes":
            return Response(
                content=midi_bytes,
                media_type="application/octet-stream",
                headers={
                    "Content-Disposition": "attachment; filename=harmony.mid",
                    "X-Chord-Info": str(chord_names_info)  # 通过header传递和弦信息
                }
            )
        else:
            # URL mode - 返回JSON格式，包含和弦信息
            return JSONResponse(content={
                "url": "https://example.com/generated/harmony.mid",
                "message": "URL mode not fully implemented in demo",
                "chord_names": [chord['chord_name'] for chord in chord_names_info],
                "chord_details": chord_names_info
            })
            
    except Exception as e:
        logger.error(f"Error in harmonize endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/evaluate", response_model=EvaluateResponse)
async def evaluate(request: EvaluateRequest):
    """
    评估音乐演奏表现
    """
    try:
        logger.info(f"Processing evaluate request with {len(request.events)} events")
        
        # 验证请求
        if request.mode != ModeEnum.EVALUATE:
            raise ValueError("Invalid mode")
        
        # 评估演奏
        evaluation_result = music_evaluator.evaluate_performance(
            events=request.events,
            reference_id=request.reference_id,
            duration_sec=request.duration_sec
        )
        
        logger.info(f"Evaluation complete. Score: {evaluation_result['score']}")
        
        return EvaluateResponse(**evaluation_result)
        
    except ValueError as e:
        # 这个会被 value_error_handler 捕获
        raise e
    except Exception as e:
        logger.error(f"Error in evaluate endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/")
async def root():
    """API 健康检查"""
    return {
        "message": "Music Harmony API is running",
        "version": "1.0.0",
        "endpoints": [
            "/api/v1/harmonize",
            "/api/v1/evaluate"
        ]
    }


@app.get("/api/v1/references")
async def get_references():
    """获取可用的参考模板列表"""
    return {
        "references": [
            {
                "id": "exercise_c_major_01",
                "name": "C Major Exercise 01",
                "description": "Basic C major scale exercise"
            }
        ]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)