from fastapi import FastAPI
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
from scipy.io import wavfile
import os
import tempfile

app = FastAPI(title="PulseBio API", version="1.0.0")

# Permitir requisições do Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pasta para salvar os áudios gerados
AUDIO_DIR = "generated_audio"
os.makedirs(AUDIO_DIR, exist_ok=True)


def gerar_binaural(
    frequencia_base: float,
    diferenca_hz: float,
    duracao_segundos: int = 180,
    sample_rate: int = 44100,
    volume: float = 0.3,
) -> str:
    """
    Gera um arquivo WAV binaural.
    
    O ouvido esquerdo recebe a frequência base.
    O ouvido direito recebe frequência base + diferença.
    O cérebro percebe a diferença como uma onda cerebral.
    
    Exemplos:
    - Theta (relaxamento): diferenca_hz = 6
    - Alpha (foco leve): diferenca_hz = 10  
    - Beta (foco intenso): diferenca_hz = 20
    - Gamma (memória): diferenca_hz = 40
    """
    t = np.linspace(0, duracao_segundos, int(sample_rate * duracao_segundos))

    # Canal esquerdo — frequência base
    esquerdo = np.sin(2 * np.pi * frequencia_base * t)

    # Canal direito — frequência base + diferença
    direito = np.sin(2 * np.pi * (frequencia_base + diferenca_hz) * t)

    # Fade in e fade out (3 segundos) para não ser abrupto
    fade_samples = int(sample_rate * 3)
    fade_in = np.linspace(0, 1, fade_samples)
    fade_out = np.linspace(1, 0, fade_samples)

    esquerdo[:fade_samples] *= fade_in
    esquerdo[-fade_samples:] *= fade_out
    direito[:fade_samples] *= fade_in
    direito[-fade_samples:] *= fade_out

    # Combinar em estéreo e ajustar volume
    stereo = np.column_stack([esquerdo, direito])
    stereo = (stereo * volume * 32767).astype(np.int16)

    # Salvar arquivo
    nome_arquivo = f"{AUDIO_DIR}/binaural_{frequencia_base}hz_{diferenca_hz}diff_{duracao_segundos}s.wav"
    wavfile.write(nome_arquivo, sample_rate, stereo)

    return nome_arquivo


# ── ENDPOINTS ───────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"status": "PulseBio API rodando!", "versao": "1.0.0"}


@app.get("/saude")
def saude():
    return {"status": "ok"}


@app.get("/binaural/destress")
def binaural_destress(duracao: int = 180):
    """
    Gera binaural para desestresse.
    Frequência theta (6 Hz) — relaxamento profundo, nervo vago.
    """
    arquivo = gerar_binaural(
        frequencia_base=200,
        diferenca_hz=6,  # Theta
        duracao_segundos=duracao,
    )
    return FileResponse(
        arquivo,
        media_type="audio/wav",
        filename="destress_binaural.wav"
    )


@app.get("/binaural/foco")
def binaural_foco(duracao: int = 180):
    """
    Gera binaural para foco.
    Frequência beta (20 Hz) — concentração e alerta focado.
    """
    arquivo = gerar_binaural(
        frequencia_base=200,
        diferenca_hz=20,  # Beta
        duracao_segundos=duracao,
    )
    return FileResponse(
        arquivo,
        media_type="audio/wav",
        filename="focus_binaural.wav"
    )


@app.get("/binaural/memoria")
def binaural_memoria(duracao: int = 180):
    """
    Gera binaural para memória.
    Frequência gamma (40 Hz) — consolidação de memória e aprendizado.
    """
    arquivo = gerar_binaural(
        frequencia_base=200,
        diferenca_hz=40,  # Gamma
        duracao_segundos=duracao,
    )
    return FileResponse(
        arquivo,
        media_type="audio/wav",
        filename="memoria_binaural.wav"
    )


@app.get("/binaural/personalizado")
def binaural_personalizado(
    frequencia_base: float = 200,
    diferenca_hz: float = 10,
    duracao: int = 180,
):
    """
    Gera binaural personalizado com parâmetros customizados.
    """
    arquivo = gerar_binaural(
        frequencia_base=frequencia_base,
        diferenca_hz=diferenca_hz,
        duracao_segundos=duracao,
    )
    return FileResponse(
        arquivo,
        media_type="audio/wav",
        filename="personalizado_binaural.wav"
    )


@app.get("/frequencias")
def listar_frequencias():
    """
    Retorna as frequências disponíveis e seus efeitos.
    """
    return {
        "frequencias": [
            {
                "nome": "Delta",
                "hz": "1-4",
                "efeito": "Sono profundo e recuperação"
            },
            {
                "nome": "Theta",
                "hz": "4-8",
                "efeito": "Relaxamento profundo e meditação"
            },
            {
                "nome": "Alpha",
                "hz": "8-12",
                "efeito": "Relaxamento focado e criatividade"
            },
            {
                "nome": "Beta",
                "hz": "13-30",
                "efeito": "Foco, concentração e alerta"
            },
            {
                "nome": "Gamma",
                "hz": "30-50",
                "efeito": "Memória, aprendizado e cognição"
            }
        ]
    }