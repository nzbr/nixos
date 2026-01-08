import plotly.graph_objs as go
import numpy as np

# Define the data points
illuminance = [0, 4, 8, 16, 64, 128, 256, 512]
light = [8, 24, 32, 48, 96, 128, 192, 255]

ref_X = np.linspace(0, 512, 100)
ref_Y = np.sqrt(ref_X * 5) * 5 + 5


# Create the plot
fig = go.Figure(data=go.Scatter(x=illuminance, y=light, mode='markers+lines', marker=dict(size=10)))
fig.add_trace(go.Scatter(x=ref_X, y=ref_Y, mode='lines', name='Reference Line', line=dict(color='red', dash='dash')))
fig.update_layout(title='Illuminance vs Light',
                  xaxis_title='Illuminance',
                  yaxis_title='Light')
fig.show()
